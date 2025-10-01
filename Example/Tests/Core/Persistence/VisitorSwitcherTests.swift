//
//  VisitorSwitcherTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class VisitorSwitcherTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    static let identityKey = "email"
    let identityValue = "identityValue"
    lazy var hashedIdentityValue: String = {
        identityValue.sha256() ?? ""
    }()
    var dataStorage: VisitorStorage!
    lazy var modulesRepository = SQLModulesRepository(dbProvider: databaseProvider)
    lazy var storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                 modulesRepository: modulesRepository)
    lazy var provider: VisitorIdProvider = VisitorIdProvider(existingVisitorId: nil,
                                                             visitorStorage: dataStorage,
                                                             logger: nil)
    var dataLayerStore: DataStore?
    @StateSubject(CoreSettings(visitorIdentityKey: VisitorSwitcherTests.identityKey))
    var coreSettings: ObservableState<CoreSettings>
    override func setUpWithError() throws {
        let dataStore = try storeProvider.getModuleStore(name: "visitor")
        dataStorage = VisitorStorage(storage: dataStore)
        dataLayerStore = try storeProvider.getModuleStore(name: "datalayer")
        guard let dataLayerStore else {
            XCTFail("Can't create DataLayer Store")
            return
        }
        _ = VisitorSwitcher.handleIdentitySwitches(visitorIdProvider: provider,
                                                   onCoreSettings: coreSettings.asObservable(),
                                                   dataLayerStore: dataLayerStore)
    }

    func storeIdentityInDataLayer(_ value: String, forKey key: String = VisitorSwitcherTests.identityKey, store: DataStore? = nil) throws {
        guard let store = store ?? dataLayerStore else {
            XCTFail("Store not found")
            return
        }
        try store.edit()
            .put(key: key, value: value, expiry: .forever)
            .commit()
    }

    func test_add_identity_to_dataLayer_associates_current_visitorId() throws {
        let visitorId = provider.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(dataStorage.visitorId, visitorId)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
    }

    func test_add_two_identities_to_dataLayer_creates_new_visitorId_associated_with_new_identity() throws {
        let initialVisitorId = provider.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
        try storeIdentityInDataLayer("otherIdentity")
        XCTAssertNotEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, "otherIdentity".sha256())
    }

    func test_switch_to_old_identity_returns_to_old_visitorId() throws {
        let initialVisitorId = provider.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
        try storeIdentityInDataLayer("otherIdentity")
        XCTAssertNotEqual(dataStorage.visitorId, initialVisitorId)
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
    }

    func test_remove_current_identity_doesnt_switch_visitorId() throws {
        let initialVisitorId = provider.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
        guard let store = dataLayerStore else {
            XCTFail("Store not found")
            return
        }
        try store.edit()
            .remove(key: Self.identityKey)
            .commit()
        XCTAssertEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
    }

    func test_change_identityKey_switches_visitorId_if_newIdentity_is_present() throws {
        let initialVisitorId = provider.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
        try storeIdentityInDataLayer("newIdentity", forKey: "newIdentityKey")
        _coreSettings.value = CoreSettings(visitorIdentityKey: "newIdentityKey")
        XCTAssertNotEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, "newIdentity".sha256())
    }

    func test_change_identityKey_doesnt_switch_identity_if_newIdentity_is_not_present() throws {
        let initialVisitorId = provider.visitorId.value
        try storeIdentityInDataLayer(identityValue)
        XCTAssertEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
        _coreSettings.value = CoreSettings(visitorIdentityKey: "newIdentityKey")
        XCTAssertEqual(dataStorage.visitorId, initialVisitorId)
        XCTAssertEqual(dataStorage.currentIdentity, hashedIdentityValue)
    }
}
