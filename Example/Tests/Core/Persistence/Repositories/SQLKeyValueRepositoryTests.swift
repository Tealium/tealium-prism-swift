//
//  SQLKeyValueRepositoryTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class SQLKeyValueRepositoryTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    lazy var repository = SQLKeyValueRepository(dbProvider: dbProvider, moduleId: 1)

    override func setUp() {
        dbProvider.database.foreignKeys = false
    }

    func test_upsert_adds_new_item() throws {
        try repository.upsert(key: "key", value: "value", expiry: .forever)
        XCTAssertEqual(repository.get(key: "key")?.get(), "value")
    }

    func test_upsert_updates_old_item() throws {
        try repository.upsert(key: "key", value: "value", expiry: .forever)
        try repository.upsert(key: "key", value: "updated", expiry: .session)
        XCTAssertEqual(repository.get(key: "key")?.get(), "updated")
        XCTAssertEqual(repository.getExpiry(key: "key"), .session)
    }

    func test_get_unused_key_returns_nil() throws {
        XCTAssertNil(repository.get(key: "key"))
    }

    func test_getAll_returns_all_items() throws {
        try repository.upsert(key: "key1", value: "value", expiry: .forever)
        try repository.upsert(key: "key2", value: "other", expiry: .forever)
        let allItems = repository.getAll()
        XCTAssertEqual(allItems.count, 2)
        XCTAssertEqual(allItems.get(key: "key1"), "value")
        XCTAssertEqual(allItems.get(key: "key2"), "other")
    }

    func test_count_returns_number_of_items() throws {
        try repository.upsert(key: "key1", value: "value", expiry: .forever)
        try repository.upsert(key: "key2", value: "other", expiry: .forever)
        XCTAssertEqual(repository.count(), 2)
    }

    func test_keys_returns_all_keys() throws {
        try repository.upsert(key: "key1", value: "value", expiry: .forever)
        try repository.upsert(key: "key2", value: "other", expiry: .forever)
        XCTAssertEqual(repository.keys().sorted(), ["key1", "key2"])
    }

    func test_contains_returns_true_for_added_key() throws {
        try repository.upsert(key: "key1", value: "value", expiry: .forever)
        XCTAssertTrue(repository.contains(key: "key1"))
    }

    func test_contains_returns_false_for_non_added_key() throws {
        try repository.upsert(key: "key1", value: "value", expiry: .forever)
        XCTAssertFalse(repository.contains(key: "key2"))
    }

    func test_getExpiry_returns_correct_expiry() throws {
        try repository.upsert(key: "forever", value: "value", expiry: .forever)
        try repository.upsert(key: "untilrestart", value: "value", expiry: .untilRestart)
        try repository.upsert(key: "session", value: "value", expiry: .session)
        let date = 5.minutes.afterNow()
        try repository.upsert(key: "date", value: "value", expiry: .after(date))

        XCTAssertEqual(repository.getExpiry(key: "forever"), .forever)
        XCTAssertEqual(repository.getExpiry(key: "untilrestart"), .untilRestart)
        XCTAssertEqual(repository.getExpiry(key: "session"), .session)
        XCTAssertEqual(repository.getExpiry(key: "date")?.expiryTime() ?? 0, Expiry.after(date).expiryTime(), accuracy: 1)
    }

    func test_getExpiry_returns_nil_when_expired() throws {
        try repository.upsert(key: "expiredDate", value: "value", expiry: .after(Date()))
        XCTAssertNil(repository.getExpiry(key: "expiredDate"))
    }

    func test_get_returns_nil_when_expired() throws {
        try repository.upsert(key: "expiredDate", value: "value", expiry: .after(Date()))
        XCTAssertNil(repository.get(key: "expiredDate"))
    }

    func test_contains_returns_nil_when_expired() throws {
        try repository.upsert(key: "expiredDate", value: "value", expiry: .after(Date()))
        XCTAssertFalse(repository.contains(key: "expiredDate"))
    }

    func test_getAll_filters_expired_out() throws {
        try repository.upsert(key: "expiredDate", value: "value", expiry: .after(Date()))
        try repository.upsert(key: "forever", value: "value", expiry: .forever)
        let nonExpiredData = repository.getAll()
        XCTAssertEqual(nonExpiredData.count, 1)
        XCTAssertEqual(nonExpiredData.get(key: "forever"), "value")
        XCTAssertNil(nonExpiredData.getDataItem(key: "expiredDate"))
    }

    func test_count_doesnt_count_expired_data() throws {
        try repository.upsert(key: "expiredDate", value: "value", expiry: .after(Date()))
        try repository.upsert(key: "forever", value: "value", expiry: .forever)
        XCTAssertEqual(repository.count(), 1)
    }

    func test_keys_filters_expired_out() throws {
        try repository.upsert(key: "expiredDate", value: "value", expiry: .after(Date()))
        try repository.upsert(key: "forever", value: "value", expiry: .forever)
        let nonExpiredKeys = repository.keys()
        XCTAssertEqual(nonExpiredKeys.count, 1)
        XCTAssertTrue(nonExpiredKeys.contains("forever"))
        XCTAssertFalse(nonExpiredKeys.contains("expiredDate"))
    }

    func test_delete_removes_item() throws {
        try repository.upsert(key: "key", value: "value", expiry: .forever)
        XCTAssertTrue(repository.contains(key: "key"))
        let count = try repository.delete(key: "key")
        XCTAssertFalse(repository.contains(key: "key"))
        XCTAssertEqual(count, 1)
    }

    func test_delete_on_missing_key_does_nothing() throws {
        try repository.upsert(key: "key", value: "value", expiry: .forever)
        XCTAssertTrue(repository.contains(key: "key"))
        let count = try repository.delete(key: "missingKey")
        XCTAssertTrue(repository.contains(key: "key"))
        XCTAssertEqual(count, 0)
    }

    func test_clear_removes_all_items() throws {
        try repository.upsert(key: "key1", value: "value", expiry: .forever)
        try repository.upsert(key: "key2", value: "value", expiry: .forever)
        XCTAssertTrue(repository.contains(key: "key1"))
        XCTAssertTrue(repository.contains(key: "key2"))
        let count = try repository.clear()
        XCTAssertFalse(repository.contains(key: "key1"))
        XCTAssertFalse(repository.contains(key: "key2"))
        XCTAssertEqual(count, 2)
    }

    func test_transactionally_runs_in_a_transaction() throws {
        try repository.upsert(key: "key", value: "value", expiry: .forever)
        XCTAssertThrowsError(try repository.transactionally { repository in
            try repository.upsert(key: "key", value: "updated", expiry: .forever)
            throw NSError(domain: "test error", code: 1)
        })
        XCTAssertEqual(repository.get(key: "key")?.get(), "value", "Value should be the same as the first because of the transaction rollback")
    }

    func test_different_moduleId_rows_are_not_affected() throws {
        try repository.upsert(key: "key", value: "value", expiry: .forever)
        let otherRepository = SQLKeyValueRepository(dbProvider: dbProvider, moduleId: 2)
        try otherRepository.upsert(key: "key", value: "updated", expiry: .forever)
        XCTAssertEqual(otherRepository.get(key: "key")?.get(), "updated")
        XCTAssertEqual(repository.get(key: "key")?.get(), "value")
        let count = try otherRepository.delete(key: "key")
        XCTAssertEqual(count, 1)
        XCTAssertFalse(otherRepository.contains(key: "key"))
        XCTAssertTrue(repository.contains(key: "key"))
    }
}
