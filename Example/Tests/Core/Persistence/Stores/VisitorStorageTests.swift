//
//  VisitorStorageTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class VisitorStorageTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    func createRawStore() throws -> any DataStore {
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
        return try storeProvider.getModuleStore(name: Modules.Types.visitorId)
    }
    var dataStore: (any DataStore)!
    var storage: VisitorStorage!
    override func setUp() {
        dataStore = XCTAssertNoThrowReturn(try createRawStore())
        guard let dataStore else {
            XCTFail("Failed to create the data store")
            return
        }
        storage = VisitorStorage(storage: dataStore)
    }

    func test_visitorId_is_null_at_the_start() {
        XCTAssertNil(storage.visitorId)
    }

    func test_visitorId_returns_visitorId_after_changeVisitor_with_nil_identity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: nil)
        XCTAssertEqual(storage.visitorId, "aVisitor")
    }

    func test_visitorId_returns_visitorId_after_changeVisitor_withIdentity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.visitorId, "aVisitor")
    }

    func test_ownerIdentity_is_null_at_the_start() {
        XCTAssertNil(storage.ownerIdentity)
    }

    func test_ownerIdentity_is_null_after_changeVisitor_with_nil_identity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: nil)
        XCTAssertNil(storage.ownerIdentity)
    }

    func test_ownerIdentity_returns_identity_after_changeVisitor_withIdentity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.ownerIdentity, "anIdentity")
    }

    func test_changeVisitor_withIdentity_replaces_both_visitorId_and_ownerIdentity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.visitorId, "aVisitor")
        XCTAssertEqual(storage.ownerIdentity, "anIdentity")
        try storage.changeVisitor("newVisitor", withIdentity: "anotherIdentity")
        XCTAssertEqual(storage.visitorId, "newVisitor")
        XCTAssertEqual(storage.ownerIdentity, "anotherIdentity")
    }

    func test_changeVisitor_withIdentity_sets_owner_and_map() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.ownerIdentity, "anIdentity")
        XCTAssertEqual(storage.getKnownVisitorId(identity: "anIdentity"), "aVisitor")
    }

    func test_changeVisitor_withIdentity_nil_removes_ownerIdentity_and_leaves_identity_rows_untouched() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        try storage.changeVisitor("newVisitor", withIdentity: nil)
        XCTAssertNil(storage.ownerIdentity)
        XCTAssertEqual(storage.visitorId, "newVisitor")
        XCTAssertEqual(storage.getKnownVisitorId(identity: "anIdentity"), "aVisitor")
    }

    func test_getKnownVisitorId_returns_previous_visitorIds() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        try storage.changeVisitor("newVisitor", withIdentity: "anotherIdentity")
        XCTAssertEqual(storage.getKnownVisitorId(identity: "anIdentity"), "aVisitor")
    }

    func test_getKnownVisitorId_returns_visitorId_after_changeVisitor_withIdentity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.getKnownVisitorId(identity: "anIdentity"), "aVisitor")
    }

    // MARK: - Row layout

    func test_visitorId_is_stored_under_the_visitor_id_key() throws {
        try storage.changeVisitor("aVisitor", withIdentity: nil)
        XCTAssertEqual(dataStore.get(key: "visitor_id"), "aVisitor")
    }

    func test_ownerIdentity_is_stored_under_the_owner_identity_key() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(dataStore.get(key: "owner_identity"), "anIdentity")
    }

    func test_knownVisitorId_association_is_stored_under_a_dotted_identity_key() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(dataStore.get(key: "identity.anIdentity"), "aVisitor")
    }

    func test_getKnownVisitorId_round_trips_the_dotted_identity_key_through_a_reopened_store() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        // A new provider doesn't share the cached store, so this reads back what was persisted, as after a relaunch.
        let reopenedStorage = VisitorStorage(storage: try createRawStore())
        XCTAssertEqual(reopenedStorage.getKnownVisitorId(identity: "anIdentity"), "aVisitor")
        XCTAssertEqual(reopenedStorage.ownerIdentity, "anIdentity")
        XCTAssertEqual(reopenedStorage.visitorId, "aVisitor")
    }

    // MARK: - eraseIdentities

    func test_eraseIdentities_withIdentity_nil_removes_identities_and_ownerIdentity_and_sets_new_visitorId() throws {
        try storage.changeVisitor("aVisitor1", withIdentity: "anIdentity1")
        try storage.changeVisitor("aVisitor2", withIdentity: "anIdentity2")
        try storage.changeVisitor("aVisitor3", withIdentity: "anIdentity3")
        try storage.eraseIdentities(settingNewVisitorId: "newVisitor", withIdentity: nil)
        XCTAssertNil(storage.getKnownVisitorId(identity: "anIdentity1"))
        XCTAssertNil(storage.getKnownVisitorId(identity: "anIdentity2"))
        XCTAssertNil(storage.getKnownVisitorId(identity: "anIdentity3"))
        XCTAssertNil(storage.ownerIdentity)
        XCTAssertEqual(storage.visitorId, "newVisitor")
    }

    func test_eraseIdentities_withIdentity_sets_owner_and_leaves_exactly_one_map_row_even_when_already_mapped() throws {
        try storage.changeVisitor("oldVisitor", withIdentity: "anIdentity")
        try storage.changeVisitor("aVisitor2", withIdentity: "anIdentity2")
        try storage.eraseIdentities(settingNewVisitorId: "newVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.ownerIdentity, "anIdentity")
        XCTAssertEqual(storage.getKnownVisitorId(identity: "anIdentity"), "newVisitor")
        XCTAssertNil(storage.getKnownVisitorId(identity: "anIdentity2"))
        let identityRows = dataStore.keys().filter { $0.hasPrefix(VisitorStorage.Keys.identityPrefix) }
        XCTAssertEqual(identityRows, [VisitorStorage.Keys.identity("anIdentity")])
    }

    func test_eraseIdentities_keeps_unrelated_rows_put_in_the_same_store() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        try dataStore.edit()
            .put(key: "unrelated_key", value: "unrelated_value", expiry: .forever)
            .commit()
        try storage.eraseIdentities(settingNewVisitorId: "newVisitor", withIdentity: nil)
        XCTAssertEqual(dataStore.get(key: "unrelated_key"), "unrelated_value")
        let keys = dataStore.keys()
        XCTAssertFalse(keys.contains { $0.hasPrefix(VisitorStorage.Keys.identityPrefix) })
        XCTAssertFalse(keys.contains(VisitorStorage.Keys.ownerIdentity))
    }
}
