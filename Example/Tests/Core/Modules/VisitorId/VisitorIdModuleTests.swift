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
    lazy var hashedIdentityValue: String = {
        identityValue.sha256() ?? ""
    }()
    var existingVisitorId: String?
    var visitorIdentityKey: String? = VisitorIdModuleTests.identityKey
    var visitorStorage: VisitorStorage!
    var dataLayerStore: (any DataStore)!
    lazy var module: VisitorIdModule = VisitorIdModule(visitorStorage: visitorStorage,
                                                       existingVisitorId: existingVisitorId,
                                                       dataLayer: dataLayerStore,
                                                       configuration: VisitorIdConfiguration(visitorIdentityKey: visitorIdentityKey),
                                                       logger: nil)

    override func setUpWithError() throws {
        let modulesRepository = SQLModulesRepository(dbProvider: databaseProvider)
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
        try visitorStorage.changeVisitor("stored")
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
        module.identify(identity: identityValue)
        let oldId = module.visitorId.value
        let oldIdentity = visitorStorage.ownerIdentity
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), oldId)
        let newId = try module.regenerate()
        XCTAssertNotEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), oldId)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), newId)
        XCTAssertEqual(module.visitorId.value, newId)
        XCTAssertEqual(visitorStorage.ownerIdentity, oldIdentity)
    }

    func test_regenerate_after_identity_is_removed_from_dataLayer_keeps_it_as_owner_of_the_new_visitorId() throws {
        _ = module
        try storeIdentityInDataLayer(identityValue)
        try dataLayerStore.edit()
            .remove(key: Self.identityKey)
            .commit()
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

    func test_identify_to_blank_identity_does_nothing() {
        module.identify(identity: identityValue)
        let initialId = module.visitorId.value
        let initialIdentityHashed = visitorStorage.ownerIdentity
        module.identify(identity: "")
        module.identify(identity: "   ")
        XCTAssertEqual(initialId, module.visitorId.value)
        XCTAssertEqual(initialIdentityHashed, visitorStorage.ownerIdentity)
    }

    func test_identify_to_old_identity_that_has_same_visitor_only_changes_the_identity() throws {
        module.identify(identity: identityValue)
        let oldVisitorId = module.visitorId.value
        guard let newVisitorHashed = "newVisitor".sha256() else {
            XCTFail("Failed to hash newVisitor")
            return
        }
        try visitorStorage.changeVisitor(module.visitorId.value, withIdentity: newVisitorHashed)
        XCTAssertEqual(visitorStorage.ownerIdentity, newVisitorHashed)
        XCTAssertEqual(module.visitorId.value, oldVisitorId)
        module.identify(identity: identityValue)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(module.visitorId.value, oldVisitorId)
    }

    // MARK: - eraseLocalHistory

    func test_eraseLocalHistory_resets_visitorId_and_clears_knownVisitorIds() throws {
        module.identify(identity: identityValue)
        let initialVisitorId = module.visitorId.value
        guard let initialIdentity = visitorStorage.ownerIdentity else {
            XCTFail("Missing initial identity")
            return
        }
        XCTAssertNotNil(visitorStorage.getKnownVisitorId(identity: initialIdentity))

        let newId = try module.eraseLocalHistory()
        XCTAssertNotEqual(initialVisitorId, newId)
        XCTAssertNil(visitorStorage.ownerIdentity)
        XCTAssertNil(visitorStorage.getKnownVisitorId(identity: initialIdentity))
    }

    func test_eraseLocalHistory_then_rewriting_same_identity_in_dataLayer_associates_it_with_new_visitorId() throws {
        try skip("MT-2237: VisitorSwitcher dedups identities, so rewriting the erased identity is not relinked in-session")
        _ = module
        try storeIdentityInDataLayer(identityValue)
        let newId = try module.eraseLocalHistory()
        // Same session as the first write: the identity must be linked again, as it would be after a relaunch.
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(module.visitorId.value, newId)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
        XCTAssertEqual(visitorStorage.getKnownVisitorId(identity: hashedIdentityValue), newId)
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
        try dataLayerStore.edit()
            .remove(key: Self.identityKey)
            .commit()
        XCTAssertEqual(visitorStorage.visitorId, initialVisitorId)
        XCTAssertEqual(visitorStorage.ownerIdentity, hashedIdentityValue)
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
