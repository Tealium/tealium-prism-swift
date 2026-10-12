//
//  VisitorIdModule+ThrowingTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class ThrowingVisitorStorage: VisitorStorage {
    struct AnError: Error {}
    let storage: any DataStore
    override init(storage: any DataStore) {
        self.storage = storage
        super.init(storage: storage)
    }
    override func changeVisitor(_ visitorId: String, withIdentity identity: String?) throws {
        throw AnError()
    }

    override func getKnownVisitorId(identity: String) -> String? {
        return nil
    }

    override func eraseIdentities(settingNewVisitorId newVisitorId: String, withIdentity identity: String?) throws {
        throw AnError()
    }
}

final class VisitorIdModuleThrowingTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    let identityValue = "identityValue"
    lazy var hashedIdentityValue: String = {
        identityValue.sha256() ?? ""
    }()
    var visitorStorage: ThrowingVisitorStorage!
    var dataLayerStore: (any DataStore)!
    lazy var module: VisitorIdModule = VisitorIdModule(visitorStorage: visitorStorage,
                                                       existingVisitorId: nil,
                                                       dataLayer: dataLayerStore,
                                                       configuration: VisitorIdConfiguration(visitorIdentityKey: nil),
                                                       logger: nil)

    override func setUpWithError() throws {
        let modulesRepository = SQLModulesRepository(dbProvider: databaseProvider)
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: modulesRepository)
        visitorStorage = ThrowingVisitorStorage(storage: try storeProvider.getModuleStore(name: Modules.Types.visitorId))
        dataLayerStore = try storeProvider.getModuleStore(name: "datalayer")
    }

    func test_init_uses_a_new_visitorId_without_persisting_it_when_visitorStorage_throws() {
        XCTAssertFalse(module.visitorId.value.isBlank)
        XCTAssertNil(visitorStorage.visitorId)
    }

    func test_identify_generates_new_visitorId_when_visitorStorage_throws() throws {
        let initialId = module.visitorId.value
        // Pre-seed an owner identity directly (bypassing the throwing overrides) so `identify`
        // takes the "already owned by another identity" branch and generates a brand new id.
        try visitorStorage.storage.edit()
            .put(key: VisitorStorage.Keys.ownerIdentity, value: "someOtherOwner", expiry: .forever)
            .commit()
        module.identify(identity: identityValue)
        XCTAssertNotEqual(module.visitorId.value, initialId)
    }

    func test_regenerate_changes_visitorId_when_visitorStorage_throws() {
        let initialId = module.visitorId.value
        XCTAssertThrowsError(try module.regenerate())
        XCTAssertNotEqual(module.visitorId.value, initialId)
    }

    func test_eraseLocalHistory_changes_visitorId_when_visitorStorage_throws() {
        let initialId = module.visitorId.value
        XCTAssertThrowsError(try module.eraseLocalHistory())
        XCTAssertNotEqual(module.visitorId.value, initialId)
    }

    func test_subscriber_of_visitorId_sees_new_id_when_regenerate_visitorStorage_throws() {
        let initialId = module.visitorId.value
        var receivedId: String?
        _ = module.visitorId.updates().subscribeOnce { newId in
            receivedId = newId
        }
        XCTAssertThrowsError(try module.regenerate())
        XCTAssertNotNil(receivedId)
        XCTAssertNotEqual(receivedId, initialId)
    }
}
