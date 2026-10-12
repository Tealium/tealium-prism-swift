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

    // MARK: - Seeding

    func test_subscribing_with_no_value_at_identityKey_emits_nothing() {
        // The subscription made in setUp has already run by the time the test body executes.
        XCTAssertEqual(identifiedValues, [])
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

    func test_same_value_written_twice_calls_identify_twice() throws {
        try storeIdentityInDataLayer("identityValue")
        try storeIdentityInDataLayer("identityValue")
        // Not deduplicated: `identify` decides whether a repeated identity needs any change.
        XCTAssertEqual(identifiedValues, ["identityValue", "identityValue"])
    }

    // MARK: - Removal and expiry

    func test_removing_value_at_identityKey_emits_nothing() throws {
        try storeIdentityInDataLayer("identityValue")
        try dataLayerStore.edit()
            .remove(key: Self.identityKey)
            .commit()
        XCTAssertEqual(identifiedValues, ["identityValue"])
    }

    func test_removed_identity_rewritten_later_calls_identify_again() throws {
        try storeIdentityInDataLayer("identityValue")
        try dataLayerStore.edit()
            .remove(key: Self.identityKey)
            .commit()
        try storeIdentityInDataLayer("identityValue")
        XCTAssertEqual(identifiedValues, ["identityValue", "identityValue"])
    }

    func test_put_then_remove_in_one_transaction_emits_nothing_when_identity_was_present() throws {
        try storeIdentityInDataLayer("identityValue")
        // The store publishes removals before updates, regardless of the order of the edits.
        try dataLayerStore.edit()
            .put(key: Self.identityKey, value: "otherIdentity", expiry: .forever)
            .remove(key: Self.identityKey)
            .commit()
        XCTAssertEqual(identifiedValues, ["identityValue"])
    }

    func test_put_then_remove_in_one_transaction_emits_nothing_when_no_identity_was_present() throws {
        try dataLayerStore.edit()
            .put(key: Self.identityKey, value: "identityValue", expiry: .forever)
            .remove(key: Self.identityKey)
            .commit()
        XCTAssertEqual(identifiedValues, [])
    }

    func test_identityKey_expiry_emits_nothing() throws {
        try dataLayerStore.edit()
            .put(key: Self.identityKey, value: "identityValue", expiry: .after(50.milliseconds.after(date: Date())))
            .commit()
        let expired = expectation(description: "Identity expires")
        expired.isInverted = true
        waitForDefaultTimeout()
        modulesRepository.deleteExpired(expiry: .restart)
        // The write itself is observed while still valid; the expiry sweep that removes it is not.
        XCTAssertEqual(identifiedValues, ["identityValue"])
    }

    func test_writing_already_expired_value_at_identityKey_emits_nothing() throws {
        try dataLayerStore.edit()
            .put(key: Self.identityKey, value: "identityValue", expiry: .after(1.seconds.before(date: Date())))
            .commit()
        XCTAssertEqual(identifiedValues, [])
    }

    // MARK: - Switching the watched key

    func test_update_to_unrelated_key_emits_nothing() throws {
        try storeIdentityInDataLayer("newIdentity", forKey: "unrelatedKey")
        XCTAssertEqual(identifiedValues, [])
    }

    func test_changing_identityKey_watches_new_key_and_calls_identify_if_value_present() throws {
        try storeIdentityInDataLayer("identityValue")
        try storeIdentityInDataLayer("newIdentity", forKey: "newIdentityKey")
        _identityKeyState.value = "newIdentityKey"
        XCTAssertEqual(identifiedValues, ["identityValue", "newIdentity"])
    }

    func test_changing_identityKey_to_key_with_no_value_emits_nothing() throws {
        try storeIdentityInDataLayer("identityValue")
        _identityKeyState.value = "newIdentityKey"
        XCTAssertEqual(identifiedValues, ["identityValue"])
    }

    func test_nil_identityKey_disables_switching() throws {
        _identityKeyState.value = nil
        try storeIdentityInDataLayer("identityValue")
        XCTAssertEqual(identifiedValues, [])
    }

    func test_disposing_stops_identify_calls() throws {
        try storeIdentityInDataLayer("identityValue")
        disposable?.dispose()
        try storeIdentityInDataLayer("otherIdentity")
        XCTAssertEqual(identifiedValues, ["identityValue"])
    }
}
