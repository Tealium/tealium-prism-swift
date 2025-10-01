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

    func test_deleteExpired_notifies_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataRemoved = expectation(description: "onDataRemoved event is notified")
        let currentDate = Date()
        try store.edit()
            .put(key: "expired", value: "value", expiry: .after(1.seconds.before(date: currentDate)))
            .put(key: "valid", value: "value", expiry: .forever)
            .commit()
        store.onDataRemoved.subscribeOnce { removedData in
            XCTAssertTrue(removedData.contains("expired"))
            XCTAssertEqual(removedData.count, 1)
            dataRemoved.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .restart)
        waitForDefaultTimeout()
    }

    func test_deleteExpired_doesnt_notify_onDataRemoved_if_noData_expired_in_this_module() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataRemoved = expectation(description: "onDataRemoved event is NOT notified")
        dataRemoved.isInverted = true
        try store.edit()
            .put(key: "expired", value: "value", expiry: .after(Date()))
            .put(key: "valid", value: "value", expiry: .forever)
            .commit()
        let anotherStore = try moduleStoreProvider.getModuleStore(name: "test2")
        try anotherStore.edit()
            .put(key: "valid", value: "value", expiry: .forever)
            .commit()
        anotherStore.onDataRemoved.subscribeOnce { _ in
            dataRemoved.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .restart)
        waitForDefaultTimeout()
    }
}
