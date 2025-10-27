//
//  VisitorIdProvider+ThrowingTests.swift
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
    override func changeVisitor(_ visitorId: String) throws {
        throw AnError()
    }

    override func changeVisitor(_ visitorId: String, withIdentity identity: String) throws {
        throw AnError()
    }

    override func changeIdentity(identity: String) throws {
        throw AnError()
    }

    override func getKnownVisitorId(identity: String) -> String? {
        return nil
    }

    override func clear(settingNewVisitorId newVisitorId: String) throws {
        throw AnError()
    }
}

final class VisitorIdProviderThrowingTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    let identityValue = "identityValue"
    lazy var hashedIdentityValue: String = {
        identityValue.sha256() ?? ""
    }()
    var dataStorage: ThrowingVisitorStorage!
    lazy var provider: VisitorIdProvider = VisitorIdProvider(existingVisitorId: nil,
                                                             visitorStorage: dataStorage,
                                                             logger: nil)
    override func setUpWithError() throws {
        let modulesRepository = SQLModulesRepository(dbProvider: databaseProvider)
        let dataStore = try ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: modulesRepository).getModuleStore(name: "visitor")
        dataStorage = ThrowingVisitorStorage(storage: dataStore)
    }

    func test_throwing_storage_creates_visitorId() {
        XCTAssertNotNil(provider.visitorId.value)
    }

    func test_identify_reset_visitorId_when_dataStorage_throws() throws {
        let initialId = provider.visitorId.value
        try dataStorage.storage.edit()
            .put(key: VisitorStorage.Keys.currentIdentity, value: identityValue, expiry: .forever)
            .commit()
        provider.identify(identity: identityValue)
        XCTAssertNotEqual(provider.visitorId.value, initialId)
    }

    func test_resetVisitorId_changes_visitorId_when_dataStorage_throws() {
        let initialId = provider.visitorId.value
        XCTAssertThrowsError(try provider.resetVisitorId())
        XCTAssertNotEqual(provider.visitorId.value, initialId)
    }

    func test_clearStoredVisitorIds_changes_visitorId_when_dataStorage_throws() {
        let initialId = provider.visitorId.value
        XCTAssertThrowsError(try provider.clearStoredVisitorIds())
        XCTAssertNotEqual(provider.visitorId.value, initialId)
    }
}
