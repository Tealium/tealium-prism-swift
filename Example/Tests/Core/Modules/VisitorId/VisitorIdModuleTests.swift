//
//  VisitorIdModuleTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 14/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class VisitorIdModuleTests: XCTestCase {
    static let identityKey = "email"
    let databaseProvider = MockDatabaseProvider()
    let identityValue = "identityValue"
    let identityValueB = "identityValueB"
    lazy var hashedIdentityValue: String = {
        identityValue.sha256() ?? ""
    }()
    var existingVisitorId: String?
    var visitorIdentityKey: String? = VisitorIdModuleTests.identityKey
    var visitorStorage: VisitorStorage!
    var dataLayerStore: (any DataStore)!
    var modulesRepository: SQLModulesRepository!
    lazy var module: VisitorIdModule = VisitorIdModule(visitorStorage: visitorStorage,
                                                       existingVisitorId: existingVisitorId,
                                                       dataLayer: dataLayerStore,
                                                       configuration: VisitorIdConfiguration(visitorIdentityKey: visitorIdentityKey),
                                                       logger: nil)

    override func setUpWithError() throws {
        modulesRepository = SQLModulesRepository(dbProvider: databaseProvider)
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: modulesRepository)
        visitorStorage = VisitorStorage(storage: try storeProvider.getModuleStore(name: Modules.Types.visitorId))
        dataLayerStore = try storeProvider.getModuleStore(name: "datalayer")
    }

    func storeIdentityInDataLayer(_ value: String, forKey key: String = VisitorIdModuleTests.identityKey) throws {
        try dataLayerStore.edit()
            .put(key: key, value: value, expiry: .forever)
            .commit()
    }

    func removeIdentityFromDataLayer(forKey key: String = VisitorIdModuleTests.identityKey) throws {
        try dataLayerStore.edit()
            .remove(key: key)
            .commit()
    }

    /// Writes an identity that expires shortly, then waits past its expiry: reads treat it as absent, but no
    /// removal is emitted until `deleteExpired` runs (only on restart or session change).
    func storeIdentityInDataLayerAndWaitForItsExpiry(_ value: String, forKey key: String = VisitorIdModuleTests.identityKey) throws {
        try dataLayerStore.edit()
            .put(key: key, value: value, expiry: .after(50.milliseconds.after(date: Date())))
            .commit()
        let expired = expectation(description: "Identity expires")
        expired.isInverted = true
        waitForDefaultTimeout()
    }

    func hashed(_ identity: String) -> String {
        guard let hashedIdentity = identity.sha256() else {
            XCTFail("Failed to hash \(identity)")
            return ""
        }
        return hashedIdentity
    }

    // MARK: - collect

    func test_collect_returns_current_visitorId() {
        let data = module.collect(DispatchContext(source: .application, initialData: [:]))
        XCTAssertEqual(data.get(key: TealiumDataKey.visitorId), module.visitorId.value)
    }

    // MARK: - existingVisitorId seeding

    func test_init_with_existingVisitorId_and_no_stored_id_uses_existingVisitorId() {
        existingVisitorId = "existing"
        XCTAssertEqual(module.visitorId.value, "existing")
    }

    func test_init_with_existingVisitorId_and_already_stored_id_ignores_existingVisitorId() throws {
        try visitorStorage.changeVisitor("stored", withIdentity: nil)
        existingVisitorId = "existing"
        XCTAssertEqual(module.visitorId.value, "stored")
    }

    func test_init_with_empty_existingVisitorId_generates_different_id() {
        existingVisitorId = ""
        XCTAssertNotEqual(module.visitorId.value, "")
    }

    func test_init_with_blank_existingVisitorId_generates_different_id() {
        existingVisitorId = " "
        XCTAssertNotEqual(module.visitorId.value, " ")
    }

    func test_init_with_existingVisitorId_and_no_stored_id_persists_existingVisitorId() {
        existingVisitorId = "existing"
        _ = module
        XCTAssertEqual(visitorStorage.visitorId, "existing")
    }

    func test_init_without_stored_id_persists_the_generated_visitorId() {
        // Read the module first: it's lazy, and creating it is what generates and stores the id.
        let visitorId = module.visitorId.value
        XCTAssertEqual(visitorStorage.visitorId, visitorId)
    }

    // MARK: - identify

    func test_identify_hashes_identities() {
        module.identify(identity: identityValue)
        XCTAssertNotNil(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue))
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
    }

    func test_identify_saves_current_visitorId_for_knownVisitorId_if_not_identified_yet() {
        module.identify(identity: identityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), module.visitorId.value)
    }

    func test_regenerate_changes_visitorId_for_current_identity() throws {
        try storeIdentityInDataLayer(identityValue)
        let oldId = module.visitorId.value
        let oldIdentity = visitorStorage.ownerIdentity
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), oldId)
        let newId = try module.regenerate()
        XCTAssertNotEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), oldId)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), newId)
        XCTAssertEqual(module.visitorId.value, newId)
        XCTAssertEqual(visitorStorage.ownerIdentity, oldIdentity)
    }

    func test_regenerate_after_identity_is_removed_from_dataLayer_leaves_new_visitorId_unowned_and_map_untouched() throws {
        _ = module
        try storeIdentityInDataLayer(identityValue)
        let oldId = module.visitorId.value
        try removeIdentityFromDataLayer()
        let newId = try module.regenerate()
        XCTAssertNil(visitorStorage.ownerIdentity)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), oldId)
        XCTAssertEqual(module.visitorId.value, newId)
    }

    func test_regenerate_after_identity_expired_but_not_yet_deleted_leaves_new_visitorId_unowned_and_map_untouched() throws {
        _ = module
        let oldId = module.visitorId.value
        try storeIdentityInDataLayerAndWaitForItsExpiry(identityValue)
        let newId = try module.regenerate()
        XCTAssertNil(visitorStorage.ownerIdentity)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), oldId)
        XCTAssertEqual(module.visitorId.value, newId)
    }

    // MARK: - Case tests (ticket MT-2237 table)

    func test_case_B_logout_regenerate_login_as_other_identity_logout_regenerate_login_as_original_identity() throws {
        try storeIdentityInDataLayer(identityValue) // A in -> V1
        let visitorIdForA = module.visitorId.value
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        try removeIdentityFromDataLayer() // A out
        XCTAssertEqual(module.visitorId.value, visitorIdForA)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        let visitorIdAfterFirstRegenerate = try module.regenerate() // V2, owner nil, map[A]==V1
        XCTAssertEqual(module.visitorId.value, visitorIdAfterFirstRegenerate)
        XCTAssertNil(visitorStorage.ownerIdentity)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        try storeIdentityInDataLayer(identityValueB) // B in -> V stays V2, owner B, map[B]==V2
        XCTAssertEqual(module.visitorId.value, visitorIdAfterFirstRegenerate)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashed(identityValueB))
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashed(identityValueB)), visitorIdAfterFirstRegenerate)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA) // map[A] untouched

        try removeIdentityFromDataLayer() // B out
        XCTAssertEqual(module.visitorId.value, visitorIdAfterFirstRegenerate)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashed(identityValueB))
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashed(identityValueB)), visitorIdAfterFirstRegenerate)

        let visitorIdAfterSecondRegenerate = try module.regenerate() // V3, owner nil
        XCTAssertEqual(module.visitorId.value, visitorIdAfterSecondRegenerate)
        XCTAssertNil(visitorStorage.ownerIdentity)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA) // map[A] untouched
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashed(identityValueB)), visitorIdAfterFirstRegenerate) // map[B] untouched

        try storeIdentityInDataLayer(identityValue) // A in -> V1, owner A
        XCTAssertEqual(module.visitorId.value, visitorIdForA)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)
    }

    func test_case_C_logout_regenerate_login_as_original_identity_restores_its_visitorId() throws {
        try storeIdentityInDataLayer(identityValue) // A in -> V1
        let visitorIdForA = module.visitorId.value
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        try removeIdentityFromDataLayer() // A out
        XCTAssertEqual(module.visitorId.value, visitorIdForA)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        let regeneratedVisitorId = try module.regenerate() // V2, owner nil
        XCTAssertEqual(module.visitorId.value, regeneratedVisitorId)
        XCTAssertNil(visitorStorage.ownerIdentity)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)
        XCTAssertNotEqual(visitorIdForA, regeneratedVisitorId)

        try storeIdentityInDataLayer(identityValue) // A in -> V1, owner A, map[A]==V1
        XCTAssertEqual(module.visitorId.value, visitorIdForA)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)
        // regenerate() with no identity present never writes a map association for the abandoned id.
    }

    func test_case_A_logout_then_different_identity_login_mints_new_visitorId() throws {
        try storeIdentityInDataLayer(identityValue) // A in -> V1
        let visitorIdForA = module.visitorId.value
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        try removeIdentityFromDataLayer() // A out
        XCTAssertEqual(module.visitorId.value, visitorIdForA)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        try storeIdentityInDataLayer(identityValueB) // B in -> new V2 (!= V1), owner B
        let visitorIdForB = module.visitorId.value
        XCTAssertNotEqual(visitorIdForB, visitorIdForA)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashed(identityValueB))
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashed(identityValueB)), visitorIdForB)
    }

    func test_case_D_regenerate_while_identity_present_rebinds_it_to_the_new_visitorId() throws {
        try storeIdentityInDataLayer(identityValue) // A in -> V1
        let visitorIdForA = module.visitorId.value
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        let newId = try module.regenerate() // V2, owner A, map[A]==V2
        XCTAssertEqual(module.visitorId.value, newId)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), newId)
        XCTAssertNotEqual(newId, visitorIdForA)
    }

    func test_case_H_regenerate_before_any_login_then_identity_adopts_the_new_visitorId() throws {
        let newId = try module.regenerate() // V2, owner nil
        XCTAssertEqual(module.visitorId.value, newId)
        XCTAssertNil(visitorStorage.ownerIdentity)
        XCTAssertNil(visitorStorage.getKnownVisitorId(identity: hashed(identityValueB)))

        try storeIdentityInDataLayer(identityValueB) // B in -> V2, owner B, map[B]==V2
        XCTAssertEqual(module.visitorId.value, newId)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashed(identityValueB))
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashed(identityValueB)), newId)
    }

    func test_logout_then_relogin_without_regenerate_restores_identity_as_owner() throws {
        try storeIdentityInDataLayer(identityValue) // A in -> V1
        let visitorIdForA = module.visitorId.value
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        try removeIdentityFromDataLayer() // A out
        XCTAssertEqual(module.visitorId.value, visitorIdForA)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)

        try storeIdentityInDataLayer(identityValue) // A in -> V1, owner A
        XCTAssertEqual(module.visitorId.value, visitorIdForA)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorIdForA)
    }

    // MARK: - Ordering

    func test_regenerate_right_after_init_observes_identity_seeded_from_dataLayer() throws {
        // Written before `module` is first touched, as on a relaunch with the user still logged in.
        try storeIdentityInDataLayer(identityValue)
        let newId = try module.regenerate()
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), newId)
    }

    func test_identify_with_new_identity_changes_visitorId() {
        module.identify(identity: identityValue)
        let initialId = module.visitorId.value
        let initialIdentityHashed = visitorStorage.ownerIdentity
        module.identify(identity: "newIdentity")
        XCTAssertNotEqual(initialId, module.visitorId.value)
        XCTAssertNotEqual(initialIdentityHashed, visitorStorage.ownerIdentity)
    }

    func test_identify_to_old_identity_reverts_to_old_visitorId() {
        module.identify(identity: identityValue)
        let initialId = module.visitorId.value
        let initialIdentityHashed = visitorStorage.ownerIdentity
        module.identify(identity: "newIdentity")
        XCTAssertNotEqual(initialId, module.visitorId.value)
        module.identify(identity: identityValue)
        XCTAssertEqual(initialId, module.visitorId.value)
        XCTAssertEqual(initialIdentityHashed, visitorStorage.ownerIdentity)
    }

    func test_identify_to_same_identity_does_nothing() {
        module.identify(identity: identityValue)
        let initialId = module.visitorId.value
        let initialIdentityHashed = visitorStorage.ownerIdentity
        module.identify(identity: identityValue)
        XCTAssertEqual(initialId, module.visitorId.value)
        XCTAssertEqual(initialIdentityHashed, visitorStorage.ownerIdentity)
    }

    func test_identify_to_blank_identity_leaves_storage_untouched() {
        module.identify(identity: identityValue)
        let initialId = module.visitorId.value
        let initialIdentityHashed = visitorStorage.ownerIdentity

        module.identify(identity: "")
        module.identify(identity: "   ")

        XCTAssertEqual(initialId, module.visitorId.value)
        XCTAssertEqual(initialIdentityHashed, visitorStorage.ownerIdentity)
    }

    func test_identify_stores_a_switch_that_failed_to_be_stored_when_the_identity_is_written_again() throws {
        let visitorStore = try ModuleStoreProvider(databaseProvider: databaseProvider,
                                                   modulesRepository: modulesRepository)
            .getModuleStore(name: Modules.Types.visitorId)
        let failOnceStorage = FailOnceVisitorStorage(storage: visitorStore)
        visitorStorage = failOnceStorage
        try visitorStorage.changeVisitor("V1", withIdentity: hashed(identityValue)) // A known with V1
        try visitorStorage.changeVisitor("V0", withIdentity: hashed(identityValueB)) // B owns the current V0
        _ = module

        failOnceStorage.failNextChangeVisitor = true
        try storeIdentityInDataLayer(identityValue) // A in -> V1 used in memory, not stored
        XCTAssertEqual(module.visitorId.value, "V1")
        XCTAssertEqual(visitorStorage.visitorId, "V0")

        try storeIdentityInDataLayer(identityValue) // A again -> V1 stored, so it is kept on relaunch
        XCTAssertEqual(visitorStorage.visitorId, "V1")
        XCTAssertEqual(visitorStorage.ownerIdentity, hashed(identityValue))
    }

    /// Fails the next `changeVisitor` once, as a transient storage error would, then stores as usual.
    final class FailOnceVisitorStorage: VisitorStorage {
        var failNextChangeVisitor = false

        override func changeVisitor(_ visitorId: String, withIdentity identity: String?) throws {
            if failNextChangeVisitor {
                failNextChangeVisitor = false
                throw ThrowingVisitorStorage.AnError()
            }
            try super.changeVisitor(visitorId, withIdentity: identity)
        }
    }

    // MARK: - eraseLocalHistory

    func test_eraseLocalHistory_clears_other_known_identities_but_reassociates_the_present_one() throws {
        // A previously-seen identity, unrelated to what's in the data layer now.
        try visitorStorage.changeVisitor("otherVisitor", withIdentity: "previousOwner")
        try storeIdentityInDataLayer(identityValue)
        let initialVisitorId = module.visitorId.value
        XCTAssertNotNil(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue))

        let newId = try module.eraseLocalHistory()
        XCTAssertNotEqual(initialVisitorId, newId)
        XCTAssertNil(visitorStorage.getKnownVisitorId(identity: "previousOwner"))
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), newId)
    }

    func test_eraseLocalHistory_reassociates_identity_present_in_dataLayer_with_new_visitorId() throws {
        _ = module
        try storeIdentityInDataLayer(identityValue)
        let newId = try module.eraseLocalHistory()
        // Re-associated immediately: no need to rewrite the key.
        XCTAssertEqual(module.visitorId.value, newId)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), newId)
    }

    func test_eraseLocalHistory_with_no_identity_present_leaves_new_visitorId_unowned() throws {
        try storeIdentityInDataLayer(identityValue)
        try removeIdentityFromDataLayer()
        let newId = try module.eraseLocalHistory()
        XCTAssertNil(visitorStorage.ownerIdentity)
        XCTAssertNil(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue))
        XCTAssertEqual(module.visitorId.value, newId)
    }

    func test_eraseLocalHistory_after_identity_expired_but_not_yet_deleted_leaves_new_visitorId_unowned() throws {
        _ = module
        try storeIdentityInDataLayerAndWaitForItsExpiry(identityValue)
        let newId = try module.eraseLocalHistory()
        XCTAssertNil(visitorStorage.ownerIdentity)
        XCTAssertNil(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue))
        XCTAssertEqual(module.visitorId.value, newId)
    }

    // MARK: - Visitor Switching driven by the data layer

    func test_setting_identity_key_in_dataLayer_associates_current_visitorId() throws {
        let visitorId = module.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(visitorStorage.visitorId, visitorId)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
    }

    func test_setting_new_identity_in_dataLayer_creates_new_visitorId_associated_with_new_identity() throws {
        let initialVisitorId = module.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(visitorStorage.visitorId, initialVisitorId)
        try storeIdentityInDataLayer("otherIdentity")
        XCTAssertNotEqual(visitorStorage.visitorId, initialVisitorId)
        XCTAssertEqual(visitorStorage.ownerIdentity, "otherIdentity".sha256())
    }

    func test_switching_back_to_known_identity_in_dataLayer_restores_associated_visitorId() throws {
        let initialVisitorId = module.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        try storeIdentityInDataLayer("otherIdentity")
        XCTAssertNotEqual(visitorStorage.visitorId, initialVisitorId)
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(visitorStorage.visitorId, initialVisitorId)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
    }

    func test_removing_identity_key_from_dataLayer_does_not_switch_visitorId() throws {
        let initialVisitorId = module.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        try removeIdentityFromDataLayer()
        XCTAssertEqual(visitorStorage.visitorId, initialVisitorId)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), initialVisitorId)
    }

    func test_identityKey_expiry_does_not_switch_visitorId() throws {
        let initialVisitorId = module.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        try dataLayerStore.edit()
            .put(key: Self.identityKey, value: identityValue, expiry: .after(1.seconds.before(date: Date())))
            .commit()
        modulesRepository.deleteExpired(expiry: .restart)
        XCTAssertEqual(visitorStorage.visitorId, initialVisitorId)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), initialVisitorId)
    }

    func test_init_with_identity_already_in_dataLayer_associates_it_with_current_visitorId() throws {
        // Written before the module exists, as on a relaunch with the user still logged in.
        try storeIdentityInDataLayer(identityValue)
        let visitorId = module.visitorId.value
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), visitorId)
    }

    func test_init_with_known_identity_already_in_dataLayer_restores_its_visitorId() throws {
        try visitorStorage.changeVisitor("knownVisitor", withIdentity: hashedIdentityValue)
        try visitorStorage.changeVisitor("otherVisitor", withIdentity: "otherIdentity".sha256() ?? "")
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(module.visitorId.value, "knownVisitor")
        XCTAssertEqual(visitorStorage.visitorId, "knownVisitor")
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
    }

    func test_shutdown_stops_identity_switching() throws {
        let visitorId = module.visitorId.value
        module.shutdown()
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(module.visitorId.value, visitorId)
        XCTAssertNil(visitorStorage.ownerIdentity)
    }

    // MARK: - updateConfiguration changes the watched identity key

    func test_updateConfiguration_with_new_visitorIdentityKey_watches_new_key() throws {
        // Establish an owner identity at the original key first: switching straight to a brand new key,
        // with no identity owned yet, would only tag the current id rather than changing it.
        try storeIdentityInDataLayer(identityValue)
        let visitorIdAfterFirstIdentity = module.visitorId.value
        try storeIdentityInDataLayer("newIdentityValue", forKey: "newIdentityKey")
        _ = module.updateConfiguration([VisitorIdConfiguration.Keys.visitorIdentityKey: "newIdentityKey"])
        XCTAssertNotEqual(module.visitorId.value, visitorIdAfterFirstIdentity)
        XCTAssertEqual(visitorStorage.ownerIdentity, "newIdentityValue".sha256())
    }

    func test_updateConfiguration_removing_visitorIdentityKey_stops_switching_at_old_key() throws {
        try storeIdentityInDataLayer(identityValue)
        let visitorIdAfterIdentity = module.visitorId.value
        _ = module.updateConfiguration([:])
        try storeIdentityInDataLayer("anotherIdentity")
        XCTAssertEqual(module.visitorId.value, visitorIdAfterIdentity)
    }

    func test_updateConfiguration_setting_visitorIdentityKey_when_none_was_configured_starts_switching() throws {
        visitorIdentityKey = nil
        let initialVisitorId = module.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        XCTAssertNil(visitorStorage.ownerIdentity)
        _ = module.updateConfiguration([VisitorIdConfiguration.Keys.visitorIdentityKey: Self.identityKey])
        // The identity already stored at the newly configured key is picked up straight away.
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        try storeIdentityInDataLayer("otherIdentity")
        XCTAssertNotEqual(module.visitorId.value, initialVisitorId)
    }

    func test_updateConfiguration_with_new_visitorIdentityKey_ignores_writes_at_the_old_key() throws {
        _ = module
        _ = module.updateConfiguration([VisitorIdConfiguration.Keys.visitorIdentityKey: "newIdentityKey"])
        try storeIdentityInDataLayer(identityValue, forKey: Self.identityKey)
        XCTAssertNil(visitorStorage.ownerIdentity)
    }
}
