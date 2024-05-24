//
//  ModuleStoreTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumSwift
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
        XCTAssertEqual(store.get(key: "key")?.getString(), "value")
        try store.edit()
            .remove(key: "key")
            .commit()
        XCTAssertNil(store.get(key: "key"))
    }

    func test_put_and_remove_multiple_item() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .putAll(dictionary: ["key1": 1, "key2": "2"], expiry: .forever)
            .commit()
        let allKeyValues = store.getAll()
        XCTAssertEqual(allKeyValues.getInt(key: "key1"), 1)
        XCTAssertEqual(allKeyValues.getString(key: "key2"), "2")
        try store.edit()
            .remove(keys: ["key1", "key2"])
            .commit()
        XCTAssertNil(store.get(key: "key1"))
        XCTAssertNil(store.get(key: "key2"))
    }

    func test_clear_removes_all_previous_items() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .putAll(dictionary: ["key1": 1, "key2": "2"], expiry: .forever)
            .commit()
        let allKeyValues = store.getAll()
        XCTAssertEqual(allKeyValues.getInt(key: "key1"), 1)
        XCTAssertEqual(allKeyValues.getString(key: "key2"), "2")
        try store.edit()
            .clear()
            .commit()
        XCTAssertNil(store.get(key: "key1"))
        XCTAssertNil(store.get(key: "key2"))
    }

    func test_clear_is_always_run_first() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        try store.edit()
            .putAll(dictionary: ["key1": 1, "key2": "2"], expiry: .forever)
            .commit()
        let allKeyValues = store.getAll()
        XCTAssertEqual(allKeyValues.getInt(key: "key1"), 1)
        XCTAssertEqual(allKeyValues.getString(key: "key2"), "2")
        try store.edit()
            .putAll(dictionary: ["key3": 3.0, "key4": true], expiry: .forever)
            .clear()
            .commit()
        let keyValuesAfterClear = store.getAll()
        XCTAssertNil(store.get(key: "key1"))
        XCTAssertNil(store.get(key: "key2"))
        XCTAssertEqual(keyValuesAfterClear.getDouble(key: "key3"), 3.0)
        XCTAssertEqual(keyValuesAfterClear.getBool(key: "key4"), true)
    }

    func test_commit_only_commits_once() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let editor = store.edit()
            .putAll(dictionary: ["key1": 1, "key2": "2"], expiry: .forever)
        try editor.commit()
        XCTAssertEqual(store.keys().sorted(), ["key1", "key2"])
        try editor
            .putAll(dictionary: ["key3": 3.0, "key4": true], expiry: .forever)
            .commit()
        XCTAssertEqual(store.keys().sorted(), ["key1", "key2"], "The second commit should do nothing")
    }

    func test_put_notifies_onDataUpdated() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataUpdated = expectation(description: "onDataUpdated event is notified")
        dataUpdated.expectedFulfillmentCount = 2
        store.onDataUpdated.subscribeOnce { updatedData in
            XCTAssertEqual(updatedData["key1"] as? Int, 0)
            dataUpdated.fulfill()
        }
        try store.edit()
            .put(key: "key1", value: 0, expiry: .forever)
            .commit()
        store.onDataUpdated.subscribeOnce { updatedData in
            XCTAssertEqual(updatedData["key1"] as? Int, 1)
            XCTAssertEqual(updatedData["key2"] as? String, "2")
            dataUpdated.fulfill()
        }
        try store.edit()
            .putAll(dictionary: ["key1": 1, "key2": "2"], expiry: .forever)
            .commit()
        waitForExpectations(timeout: 2.0)
    }

    func test_remove_notifies_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataRemoved = expectation(description: "onDataRemoved event is notified")
        dataRemoved.expectedFulfillmentCount = 2
        try store.edit()
            .putAll(dictionary: ["key1": 1, "key2": "2", "key3": 3.0], expiry: .forever)
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
        waitForExpectations(timeout: 2.0)
    }

    func test_clear_notifies_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataRemoved = expectation(description: "onDataRemoved event is notified")
        try store.edit()
            .putAll(dictionary: ["key1": 1, "key2": "2", "key3": 3.0], expiry: .forever)
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
        waitForExpectations(timeout: 2.0)
    }

    func test_deleteExpired_notifies_onDataRemoved() throws {
        let store = try moduleStoreProvider.getModuleStore(name: "test")
        let dataRemoved = expectation(description: "onDataRemoved event is notified")
        let currentDate = Date()
        try store.edit()
            .put(key: "expired", value: "value", expiry: .after(currentDate.addSeconds(-1) ?? currentDate))
            .put(key: "valid", value: "value", expiry: .forever)
            .commit()
        store.onDataRemoved.subscribeOnce { removedData in
            XCTAssertTrue(removedData.contains("expired"))
            XCTAssertEqual(removedData.count, 1)
            dataRemoved.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .restart)
        waitForExpectations(timeout: 2.0)
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
        waitForExpectations(timeout: 1.0)
    }
}
