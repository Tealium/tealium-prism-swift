//
//  VisitorIdProviderTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 14/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class VisitorIdProviderTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    let identityValue = "identityValue"
    lazy var hashedIdentityValue: String = {
        identityValue.sha256() ?? ""
    }()
    var existingVisitorId: String?
    var dataStorage: VisitorStorage!
    lazy var provider: VisitorIdProvider = VisitorIdProvider(existingVisitorId: existingVisitorId,
                                                             visitorStorage: dataStorage,
                                                             logger: nil)

    override func setUpWithError() throws {
        let modulesRepository = SQLModulesRepository(dbProvider: databaseProvider)
        let dataStore = try ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: modulesRepository).getModuleStore(name: "visitor")
        dataStorage = VisitorStorage(storage: dataStore)
    }

    func test_init_with_existingVisitorId_publishes_it_in_visitorId() {
        existingVisitorId = "existing"
        XCTAssertEqual(provider.visitorId.value, "existing")
    }

    func test_init_with_empty_existingVisitorId_publishes_different_id_in_visitorId() {
        existingVisitorId = ""
        XCTAssertNotEqual(provider.visitorId.value, "")
    }

    func test_init_with_blank_existingVisitorId_publishes_different_id_in_visitorId() {
        existingVisitorId = " "
        XCTAssertNotEqual(provider.visitorId.value, " ")
    }

    func test_identify_hashes_identities() {
        provider.identify(identity: identityValue)
        XCTAssertNotNil(dataStorage.getKnownVisitorId(identity: hashedIdentityValue))
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
    }

    func test_identify_saves_current_visitorId_for_knownVisitorId_if_not_identified_yet() {
        provider.identify(identity: identityValue)
        XCTAssertEqual(dataStorage.getKnownVisitorId(identity: hashedIdentityValue), provider.visitorId.value)
    }

    func test_resetVisitorId_changes_visitorId_for_current_identity() throws {
        provider.identify(identity: identityValue)
        let oldId = provider.visitorId.value
        let oldIdentity = dataStorage.currentIdentity
        XCTAssertEqual(dataStorage.getKnownVisitorId(identity: hashedIdentityValue), oldId)
        let newId = try provider.resetVisitorId()
        XCTAssertNotEqual(dataStorage.getKnownVisitorId(identity: hashedIdentityValue), oldId)
        XCTAssertEqual(dataStorage.getKnownVisitorId(identity: hashedIdentityValue), newId)
        XCTAssertEqual(provider.visitorId.value, newId)
        XCTAssertEqual(dataStorage.currentIdentity, oldIdentity)
    }

    func test_identify_with_new_identity_changes_visitorId() {
        provider.identify(identity: identityValue)
        let initialId = provider.visitorId.value
        let initialIdentityHashed = dataStorage.currentIdentity
        provider.identify(identity: "newIdentity")
        XCTAssertNotEqual(initialId, provider.visitorId.value)
        XCTAssertNotEqual(initialIdentityHashed, dataStorage.currentIdentity)
    }

    func test_identify_to_old_identity_reverts_to_old_visitorId() {
        provider.identify(identity: identityValue)
        let initialId = provider.visitorId.value
        let initialIdentityHashed = dataStorage.currentIdentity
        provider.identify(identity: "newIdentity")
        let newId = provider.visitorId.value
        let newIdentityHashed = dataStorage.currentIdentity
        XCTAssertNotEqual(initialId, newId)
        XCTAssertNotEqual(initialIdentityHashed, newIdentityHashed)
        provider.identify(identity: identityValue)
        XCTAssertEqual(initialId, provider.visitorId.value)
        XCTAssertEqual(initialIdentityHashed, dataStorage.currentIdentity)
    }

    func test_identify_to_same_identity_does_nothing() {
        provider.identify(identity: identityValue)
        let initialId = provider.visitorId.value
        let initialIdentityHashed = dataStorage.currentIdentity
        provider.identify(identity: identityValue)
        let newId = provider.visitorId.value
        let newIdentityHashed = dataStorage.currentIdentity
        XCTAssertEqual(initialId, newId)
        XCTAssertEqual(initialIdentityHashed, newIdentityHashed)
    }

    func test_identify_to_blank_identity_does_nothing() {
        provider.identify(identity: identityValue)
        let initialId = provider.visitorId.value
        let initialIdentityHashed = dataStorage.currentIdentity
        provider.identify(identity: "")
        provider.identify(identity: "   ")
        let newId = provider.visitorId.value
        let newIdentityHashed = dataStorage.currentIdentity
        XCTAssertEqual(initialId, newId)
        XCTAssertEqual(initialIdentityHashed, newIdentityHashed)
    }

    func test_identify_to_old_identity_that_has_same_visitor_only_changes_the_identity() throws {
        provider.identify(identity: identityValue)
        let oldVisitorId = provider.visitorId.value
        guard let newVisitorHashed = "newVisitor".sha256() else {
            XCTFail("Failed to hash newVisitor")
            return
        }
        try dataStorage.changeVisitor(provider.visitorId.value, withIdentity: newVisitorHashed)
        XCTAssertEqual(dataStorage.currentIdentity, newVisitorHashed)
        XCTAssertEqual(provider.visitorId.value, oldVisitorId)
        provider.identify(identity: identityValue)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
        XCTAssertEqual(provider.visitorId.value, oldVisitorId)
    }

    func test_clearStoredVisitorIds_resets_visitor_id_and_clears_knownVisitorIds() throws {
        provider.identify(identity: identityValue)
        let initialVisitorId = provider.visitorId.value
        guard let initialIdentity = dataStorage.currentIdentity else {
            XCTFail("Missing initial identity")
            return
        }
        XCTAssertNotNil(dataStorage.getKnownVisitorId(identity: initialIdentity))

        let newId = try provider.clearStoredVisitorIds()
        XCTAssertNotEqual(initialVisitorId, newId)
        XCTAssertNil(dataStorage.currentIdentity)
        XCTAssertNil(dataStorage.getKnownVisitorId(identity: initialIdentity))
    }

}
