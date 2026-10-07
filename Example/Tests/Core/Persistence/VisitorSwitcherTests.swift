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
    static let identityKey = "email"
    let databaseProvider = MockDatabaseProvider()
    lazy var modulesRepository = SQLModulesRepository(dbProvider: databaseProvider)
    lazy var storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                 modulesRepository: modulesRepository)
    var dataLayerStore: (any DataStore)!
    var identifiedValues: [String] = []
    var disposable: (any Disposable)?

    @StateSubject<String?>(VisitorSwitcherTests.identityKey)
    var identityKeyState

    override func setUpWithError() throws {
        dataLayerStore = try storeProvider.getModuleStore(name: "datalayer")
        disposable = VisitorSwitcher.handleIdentitySwitches(onIdentityKey: identityKeyState,
                                                            dataLayerStore: dataLayerStore) { [weak self] identity in
            self?.identifiedValues.append(identity)
        }
    }

    func storeIdentityInDataLayer(_ value: String, forKey key: String = VisitorSwitcherTests.identityKey) throws {
        try dataLayerStore.edit()
            .put(key: key, value: value, expiry: .forever)
            .commit()
    }

    func test_value_present_at_identityKey_calls_identify() throws {
        try storeIdentityInDataLayer("identityValue")
        XCTAssertEqual(identifiedValues, ["identityValue"])
    }

    func test_value_changing_at_identityKey_calls_identify_again() throws {
        try storeIdentityInDataLayer("identityValue")
        try storeIdentityInDataLayer("otherIdentity")
        XCTAssertEqual(identifiedValues, ["identityValue", "otherIdentity"])
    }

    func test_removing_value_at_identityKey_does_not_call_identify_again() throws {
        try storeIdentityInDataLayer("identityValue")
        try dataLayerStore.edit()
            .remove(key: Self.identityKey)
            .commit()
        XCTAssertEqual(identifiedValues, ["identityValue"])
    }

    func test_changing_identityKey_watches_new_key_and_calls_identify_if_value_present() throws {
        try storeIdentityInDataLayer("identityValue")
        try storeIdentityInDataLayer("newIdentity", forKey: "newIdentityKey")
        _identityKeyState.value = "newIdentityKey"
        XCTAssertEqual(identifiedValues, ["identityValue", "newIdentity"])
    }

    func test_changing_identityKey_does_not_call_identify_if_new_key_has_no_value() throws {
        try storeIdentityInDataLayer("identityValue")
        _identityKeyState.value = "newIdentityKey"
        XCTAssertEqual(identifiedValues, ["identityValue"])
    }

    func test_nil_identityKey_disables_switching() throws {
        _identityKeyState.value = nil
        try storeIdentityInDataLayer("identityValue")
        XCTAssertTrue(identifiedValues.isEmpty)
    }

    func test_disposing_stops_identify_calls() throws {
        try storeIdentityInDataLayer("identityValue")
        disposable?.dispose()
        try storeIdentityInDataLayer("otherIdentity")
        XCTAssertEqual(identifiedValues, ["identityValue"])
    }
}
