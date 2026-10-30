//
//  ModuleStoreTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 13/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

final class ModuleStoreTests: XCTestCase {
    var dbProvider = MockDatabaseProvider()
    lazy var modulesRepository = SQLModulesRepository(dbProvider: self.dbProvider)
    var moduleStoreProvider: ModuleStoreProvider {
        ModuleStoreProvider(databaseProvider: self.dbProvider,
                            modulesRepository: modulesRepository)
    }
    var events: [StoreEvent] = []
    let disposer = Disposables.automatic()

    /// Records every event emitted by `store`, in emission order, into `events`.
    func recordEvents(of store: any DataStore) {
        store.onDataUpdated.subscribe { [weak self] in self?.events.append(.updated($0)) }.addTo(disposer)
        store.onDataRemoved.subscribe { [weak self] in self?.events.append(.removed($0)) }.addTo(disposer)
    }

    func test_put_and_remove_single_item() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .put(key: "key", value: "value", expiry: .forever)
            .commit()
        XCTAssertEqual(store.get(key: "key"), "value")
        try store.edit()
            .remove(key: "key")
            .commit()
        XCTAssertNil(store.getDataItem(key: "key"))
    }

    func test_put_and_remove_multiple_item() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .putAll(dataObject: ["key1": 1, "key2": "2"], expiry: .forever)
            .commit()
        let allKeyValues = store.getAll()
        XCTAssertEqual(allKeyValues.get(key: "key1"), 1)
        XCTAssertEqual(allKeyValues.get(key: "key2"), "2")
        try store.edit()
            .remove(keys: ["key1", "key2"])
            .commit()
        XCTAssertNil(store.getDataItem(key: "key1"))
        XCTAssertNil(store.getDataItem(key: "key2"))
    }

    func test_clear_removes_all_previous_items() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .putAll(dataObject: ["key1": 1, "key2": "2"], expiry: .forever)
            .commit()
        let allKeyValues = store.getAll()
        XCTAssertEqual(allKeyValues.get(key: "key1"), 1)
        XCTAssertEqual(allKeyValues.get(key: "key2"), "2")
        try store.edit()
            .clear()
            .commit()
        XCTAssertNil(store.getDataItem(key: "key1"))
        XCTAssertNil(store.getDataItem(key: "key2"))
    }

    func test_clear_is_always_run_first() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .putAll(dataObject: ["key1": 1, "key2": "2"], expiry: .forever)
            .commit()
        let allKeyValues = store.getAll()
        XCTAssertEqual(allKeyValues.get(key: "key1"), 1)
        XCTAssertEqual(allKeyValues.get(key: "key2"), "2")
        try store.edit()
            .putAll(dataObject: ["key3": 3.0, "key4": true], expiry: .forever)
            .clear()
            .commit()
        let keyValuesAfterClear = store.getAll()
        XCTAssertNil(store.getDataItem(key: "key1"))
        XCTAssertNil(store.getDataItem(key: "key2"))
        XCTAssertEqual(keyValuesAfterClear.get(key: "key3"), 3.0)
        XCTAssertEqual(keyValuesAfterClear.get(key: "key4"), true)
    }

    func test_commit_only_commits_once() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let editor = store.edit()
            .putAll(dataObject: ["key1": 1, "key2": "2"], expiry: .forever)
        try editor.commit()
        XCTAssertEqual(store.keys().sorted(), ["key1", "key2"])
        try editor
            .putAll(dataObject: ["key3": 3.0, "key4": true], expiry: .forever)
            .commit()
        XCTAssertEqual(store.keys().sorted(), ["key1", "key2"], "The second commit should do nothing")
    }

    func test_commit_with_no_edits_seals_the_editor() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let editor = store.edit()
        try editor.commit()
        try editor
            .put(key: "key", value: "value", expiry: .forever)
            .commit()
        XCTAssertNil(store.getDataItem(key: "key"), "An empty commit should seal the editor, so a later put should be discarded")
    }

    func test_commit_after_a_failed_commit_does_nothing() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let editor = store.edit()
        XCTAssertThrowsError(try editor.put(key: "bad", value: ThrowingDataInput(), expiry: .forever).commit())
        var dataUpdated = false
        store.onDataUpdated.subscribeOnce { _ in
            dataUpdated = true
        }
        try editor.put(key: "key", value: "value", expiry: .forever).commit()
        XCTAssertNil(store.getDataItem(key: "key"), "The editor should be sealed after a failed commit, so a later put should be discarded")
        XCTAssertNil(store.getDataItem(key: "bad"))
        XCTAssertFalse(dataUpdated, "No onDataUpdated event should be emitted after the editor is sealed by a failed commit")
    }

    func test_put_notifies_onDataUpdated() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataUpdated = expectation(description: "onDataUpdated event is notified")
        dataUpdated.expectedFulfillmentCount = 2
        store.onDataUpdated.subscribeOnce { updatedData in
            XCTAssertEqual(updatedData.get(key: "key1"), 0)
            dataUpdated.fulfill()
        }
        try store.edit()
            .put(key: "key1", value: 0, expiry: .forever)
            .commit()
        store.onDataUpdated.subscribeOnce { updatedData in
            XCTAssertEqual(updatedData.get(key: "key1"), 1)
            XCTAssertEqual(updatedData.get(key: "key2"), "2")
            dataUpdated.fulfill()
        }
        try store.edit()
            .putAll(dataObject: ["key1": 1, "key2": "2"], expiry: .forever)
            .commit()
        waitForDefaultTimeout()
    }

    func test_remove_notifies_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataRemoved = expectation(description: "onDataRemoved event is notified")
        dataRemoved.expectedFulfillmentCount = 2
        try store.edit()
            .putAll(dataObject: ["key1": 1, "key2": "2", "key3": 3.0], expiry: .forever)
            .commit()
        store.onDataRemoved.subscribeOnce { removedData in
            XCTAssertTrue(removedData.contains("key1"))
            XCTAssertEqual(removedData.count, 1)
            dataRemoved.fulfill()
        }
        try store.edit()
            .remove(key: "key1")
            .commit()
        store.onDataRemoved.subscribeOnce { removedData in
            XCTAssertTrue(removedData.contains("key2"))
            XCTAssertTrue(removedData.contains("key3"))
            XCTAssertEqual(removedData.count, 2)
            dataRemoved.fulfill()
        }
        try store.edit()
            .remove(keys: ["key2", "key3"])
            .commit()
        waitForDefaultTimeout()
    }

    func test_clear_notifies_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataRemoved = expectation(description: "onDataRemoved event is notified")
        try store.edit()
            .putAll(dataObject: ["key1": 1, "key2": "2", "key3": 3.0], expiry: .forever)
            .commit()
        store.onDataRemoved.subscribeOnce { removedData in
            XCTAssertTrue(removedData.contains("key1"))
            XCTAssertTrue(removedData.contains("key2"))
            XCTAssertTrue(removedData.contains("key3"))
            XCTAssertEqual(removedData.count, 3)
            dataRemoved.fulfill()
        }
        try store.edit()
            .clear()
            .commit()
        waitForDefaultTimeout()
    }

    func test_already_expired_put_on_missing_key_stores_nothing_and_emits_nothing() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        recordEvents(of: store)
        try store.edit()
            .put(key: "key", value: "value", expiry: .after(1.seconds.before(date: Date())))
            .commit()
        XCTAssertNil(store.getDataItem(key: "key"))
        XCTAssertEqual(events, [])
    }

    func test_already_expired_put_over_existing_value_deletes_it_and_emits_only_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .put(key: "key", value: "value", expiry: .forever)
            .commit()
        recordEvents(of: store)
        try store.edit()
            .put(key: "key", value: "newValue", expiry: .after(1.seconds.before(date: Date())))
            .commit()
        XCTAssertNil(store.getDataItem(key: "key"))
        XCTAssertEqual(events, [.removed(["key"])])
    }

    func test_already_expired_put_with_date_before_1970_is_applied_as_a_removal() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .put(key: "key", value: "value", expiry: .forever)
            .commit()
        recordEvents(of: store)
        try store.edit()
            .put(key: "key", value: "newValue", expiry: .after(.distantPast))
            .commit()
        XCTAssertNil(store.getDataItem(key: "key"))
        XCTAssertEqual(events, [.removed(["key"])])
    }

    func test_put_with_future_expiry_is_stored_and_emits_onDataUpdated() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        recordEvents(of: store)
        try store.edit()
            .put(key: "key", value: "value", expiry: .after(60.seconds.after(date: Date())))
            .commit()
        XCTAssertEqual(store.get(key: "key"), "value")
        XCTAssertEqual(events, [.updated(["key": "value"])])
    }

    func test_future_put_a_and_expired_put_b_in_one_transaction_emit_updated_and_removed_separately() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .put(key: "b", value: "value", expiry: .forever)
            .commit()
        recordEvents(of: store)
        let now = Date()
        try store.edit()
            .put(key: "a", value: "value", expiry: .after(60.seconds.after(date: now)))
            .put(key: "b", value: "newValue", expiry: .after(1.seconds.before(date: now)))
            .commit()
        XCTAssertEqual(store.get(key: "a"), "value")
        XCTAssertNil(store.getDataItem(key: "b"))
        XCTAssertEqual(events, [.updated(["a": "value"]), .removed(["b"])])
    }

    func test_put_then_remove_same_key_notifies_only_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        recordEvents(of: store)
        try store.edit()
            .put(key: "key", value: "value", expiry: .forever)
            .remove(key: "key")
            .commit()
        XCTAssertNil(store.getDataItem(key: "key"))
        XCTAssertEqual(events, [.removed(["key"])])
    }

    func test_remove_then_put_same_key_notifies_only_onDataUpdated() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .put(key: "key", value: "old", expiry: .forever)
            .commit()
        recordEvents(of: store)
        try store.edit()
            .remove(key: "key")
            .put(key: "key", value: "value", expiry: .forever)
            .commit()
        XCTAssertEqual(store.get(key: "key"), "value")
        XCTAssertEqual(events, [.updated(["key": "value"])])
    }

    func test_put_twice_same_key_notifies_onDataUpdated_with_last_value() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        recordEvents(of: store)
        try store.edit()
            .put(key: "key", value: "value1", expiry: .forever)
            .put(key: "key", value: "value2", expiry: .forever)
            .commit()
        XCTAssertEqual(store.get(key: "key"), "value2")
        XCTAssertEqual(events, [.updated(["key": "value2"])])
    }

    func test_put_and_remove_different_keys_notifies_onDataUpdated_before_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .put(key: "removed", value: "value", expiry: .forever)
            .commit()
        recordEvents(of: store)
        try store.edit()
            .put(key: "added", value: "value", expiry: .forever)
            .remove(key: "removed")
            .commit()
        XCTAssertEqual(events, [.updated(["added": "value"]), .removed(["removed"])])
    }

    func test_clear_then_put_notifies_key_only_as_updated() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .putAll(dataObject: ["key": "old", "other": "value"], expiry: .forever)
            .commit()
        recordEvents(of: store)
        try store.edit()
            .clear()
            .put(key: "key", value: "value", expiry: .forever)
            .commit()
        XCTAssertEqual(events, [.updated(["key": "value"]), .removed(["other"])])
    }

    func test_put_then_already_expired_put_same_key_notifies_only_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        recordEvents(of: store)
        try store.edit()
            .put(key: "key", value: "value", expiry: .forever)
            .put(key: "key", value: "newValue", expiry: .after(1.seconds.before(date: Date())))
            .commit()
        XCTAssertNil(store.getDataItem(key: "key"))
        XCTAssertEqual(events, [.removed(["key"])])
    }

    func test_deleteExpired_notifies_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataRemoved = expectation(description: "onDataRemoved event is notified")
        let currentDate = Date()
        try store.edit()
            .put(key: "expired", value: "value", expiry: .after(1.seconds.after(date: currentDate)))
            .put(key: "valid", value: "value", expiry: .forever)
            .commit()
        store.onDataRemoved.subscribeOnce { removedData in
            XCTAssertTrue(removedData.contains("expired"))
            XCTAssertEqual(removedData.count, 1)
            dataRemoved.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .restart, date: 2.seconds.after(date: currentDate))
        waitForDefaultTimeout()
    }

    func test_deleteExpired_doesnt_notify_onDataRemoved_if_noData_expired_in_this_module() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataRemoved = expectation(description: "onDataRemoved event is NOT notified")
        dataRemoved.isInverted = true
        let currentDate = Date()
        try store.edit()
            .put(key: "expired", value: "value", expiry: .after(1.seconds.after(date: currentDate)))
            .put(key: "valid", value: "value", expiry: .forever)
            .commit()
        let anotherStore = try moduleStoreProvider.getModuleStore(name: "test2")
        try anotherStore.edit()
            .put(key: "valid", value: "value", expiry: .forever)
            .commit()
        anotherStore.onDataRemoved.subscribeOnce { _ in
            dataRemoved.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .restart, date: 2.seconds.after(date: currentDate))
        waitForDefaultTimeout()
    }
}

/// An event emitted by a `DataStore`, recorded by `ModuleStoreTests.recordEvents(of:)`.
enum StoreEvent: Equatable {
    case updated(DataObject)
    case removed([String])
}

/// A `DataInput` that is not `Encodable` and doesn't match any of the special-cased types in `AnyEncodable`,
/// so serializing it always throws an `EncodingError`. Used to simulate a repository write failure.
private struct ThrowingDataInput: DataInput {}
