//
//  SQLModulesRepositoryTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 15/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SQLite3
@testable import TealiumPrism
import XCTest

final class SQLModulesRepositoryTests: XCTestCase {

    let dbProvider = MockDatabaseProvider()
    lazy var modulesRepository = SQLModulesRepository(dbProvider: dbProvider)

    func test_registerModule_registers_first_module() {
        let moduleId = XCTAssertNoThrowReturn(try modulesRepository.registerModule(name: "test"))
        XCTAssertEqual(moduleId, 1)
    }

    func test_registerModule_increments_moduleId_for_subsequent_modules() {
        let moduleId = XCTAssertNoThrowReturn(try modulesRepository.registerModule(name: "test1"))
        XCTAssertEqual(moduleId, 1)
        let moduleId2 = XCTAssertNoThrowReturn(try modulesRepository.registerModule(name: "test2"))
        XCTAssertEqual(moduleId2, 2)
    }

    func test_registerModule_returns_same_moduleId_for_same_module() {
        let moduleId = XCTAssertNoThrowReturn(try modulesRepository.registerModule(name: "test"))
        XCTAssertEqual(moduleId, 1)
        let moduleId2 = XCTAssertNoThrowReturn(try modulesRepository.registerModule(name: "test"))
        XCTAssertEqual(moduleId2, 1)
    }

    func test_getModules_returns_all_registered_modules() {
        let moduleId = XCTAssertNoThrowReturn(try modulesRepository.registerModule(name: "test1"))
        XCTAssertEqual(moduleId, 1)
        let moduleId2 = XCTAssertNoThrowReturn(try modulesRepository.registerModule(name: "test2"))
        XCTAssertEqual(moduleId2, 2)
        let modules = modulesRepository.getModules()
        XCTAssertEqual(modules["test1"], 1)
        XCTAssertEqual(modules["test2"], 2)
        XCTAssertEqual(modules.count, 2)
    }

    func setupDBForTwoModulesAndExpiredData() throws -> (SQLKeyValueRepository, SQLKeyValueRepository) {
        let moduleId1 = try modulesRepository.registerModule(name: "test1")
        let moduleId2 = try modulesRepository.registerModule(name: "test2")
        let keyValueRepository1 = SQLKeyValueRepository(dbProvider: dbProvider, moduleId: moduleId1)
        let keyValueRepository2 = SQLKeyValueRepository(dbProvider: dbProvider, moduleId: moduleId2)
        let expiredDate = 1.seconds.beforeNow()
        try keyValueRepository1.upsert(key: "expired", value: "value", expiry: .after(expiredDate))
        try keyValueRepository1.upsert(key: "restart", value: "value", expiry: .untilRestart)
        try keyValueRepository1.upsert(key: "session", value: "value", expiry: .session)
        try keyValueRepository1.upsert(key: "non-expired", value: "value", expiry: .afterCustom(timeFrame: 1.days))
        try keyValueRepository1.upsert(key: "forever", value: "value", expiry: .forever)
        try keyValueRepository2.upsert(key: "expired", value: "value", expiry: .after(expiredDate))
        try keyValueRepository2.upsert(key: "restart", value: "value", expiry: .untilRestart)
        try keyValueRepository2.upsert(key: "session", value: "value", expiry: .session)
        try keyValueRepository2.upsert(key: "non-expired", value: "value", expiry: .afterCustom(timeFrame: 1.days))
        try keyValueRepository2.upsert(key: "forever", value: "value", expiry: .forever)
        return (keyValueRepository1, keyValueRepository2)
    }

    func test_deleteExpired_removes_all_expired_and_untilRestart_data_for_all_modules() {
        guard let (kvRepository1, kvRepository2) = XCTAssertNoThrowReturn(try setupDBForTwoModulesAndExpiredData()) else {
            XCTFail("Failed to setup DB")
            return
        }
        modulesRepository.deleteExpired(expiry: .restart)
        let allKeyValues1 = kvRepository1.getAll().asDictionary()
        XCTAssertNil(allKeyValues1["expired"])
        XCTAssertNil(allKeyValues1["restart"])
        XCTAssertNotNil(allKeyValues1["session"])
        XCTAssertNotNil(allKeyValues1["non-expired"])
        XCTAssertNotNil(allKeyValues1["forever"])
        let allKeyValues2 = kvRepository2.getAll().asDictionary()
        XCTAssertNil(allKeyValues2["expired"])
        XCTAssertNil(allKeyValues2["restart"])
        XCTAssertNotNil(allKeyValues2["session"])
        XCTAssertNotNil(allKeyValues2["non-expired"])
        XCTAssertNotNil(allKeyValues2["forever"])
    }

    func test_deleteExpired_removes_all_expired_and_session_data_for_all_modules() {
        guard let (kvRepository1, kvRepository2) = XCTAssertNoThrowReturn(try setupDBForTwoModulesAndExpiredData()) else {
            XCTFail("Failed to setup DB")
            return
        }
        modulesRepository.deleteExpired(expiry: .sessionChange)
        let allKeyValues1 = kvRepository1.getAll().asDictionary()
        XCTAssertNil(allKeyValues1["expired"])
        XCTAssertNotNil(allKeyValues1["restart"])
        XCTAssertNil(allKeyValues1["session"])
        XCTAssertNotNil(allKeyValues1["non-expired"])
        XCTAssertNotNil(allKeyValues1["forever"])
        let allKeyValues2 = kvRepository2.getAll().asDictionary()
        XCTAssertNil(allKeyValues2["expired"])
        XCTAssertNotNil(allKeyValues2["restart"])
        XCTAssertNil(allKeyValues2["session"])
        XCTAssertNotNil(allKeyValues2["non-expired"])
        XCTAssertNotNil(allKeyValues2["forever"])
    }

    func test_deleteExpired_notifies_onExpiredData_event_with_expired_data() {
        guard let _ = XCTAssertNoThrowReturn(try setupDBForTwoModulesAndExpiredData()) else {
            XCTFail("Failed to setup DB")
            return
        }
        let eventNotified = expectation(description: "onDataExpired event notified")
        modulesRepository.onDataExpired.subscribeOnce { event in
            let allKeyValues1 = event[1]
            XCTAssertNotNil(allKeyValues1?["expired"])
            XCTAssertNotNil(allKeyValues1?["restart"])
            XCTAssertNil(allKeyValues1?["session"])
            XCTAssertNil(allKeyValues1?["non-expired"])
            XCTAssertNil(allKeyValues1?["forever"])
            let allKeyValues2 = event[2]
            XCTAssertNotNil(allKeyValues2?["expired"])
            XCTAssertNotNil(allKeyValues2?["restart"])
            XCTAssertNil(allKeyValues2?["session"])
            XCTAssertNil(allKeyValues2?["non-expired"])
            XCTAssertNil(allKeyValues2?["forever"])
            eventNotified.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .restart)
        waitForDefaultTimeout()
    }

    func test_deleteExpired_doesnt_notify_onExpiredData_event_if_nothing_expired() throws {
        let moduleId = try modulesRepository.registerModule(name: "test")
        let keyValueRepository = SQLKeyValueRepository(dbProvider: dbProvider, moduleId: moduleId)
        try keyValueRepository.upsert(key: "non-expired", value: "value", expiry: .afterCustom(timeFrame: 1.days))
        let eventNotified = expectation(description: "onDataExpired event is NOT notified")
        eventNotified.isInverted = true
        let subscription = modulesRepository.onDataExpired.subscribe { _ in
            eventNotified.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .restart)
        waitForDefaultTimeout()
        subscription.dispose()
    }

    func test_deleteExpired_removes_data_whose_expiry_equals_the_date() throws {
        let moduleId = try modulesRepository.registerModule(name: "test")
        let keyValueRepository = SQLKeyValueRepository(dbProvider: dbProvider, moduleId: moduleId)
        // Far in the future so the read filter would still return the row if the purge missed it.
        let date = Date(unixMilliseconds: 4_102_444_800_000)
        try keyValueRepository.upsert(key: "boundary", value: "value", expiry: .after(date))
        let eventNotified = expectation(description: "onDataExpired event notified")
        modulesRepository.onDataExpired.subscribeOnce { event in
            XCTAssertNotNil(event[moduleId]?["boundary"])
            eventNotified.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .sessionChange, date: date)
        waitForDefaultTimeout()
        XCTAssertNil(keyValueRepository.getAll().asDictionary()["boundary"])
    }

    func test_deleteExpired_keeps_data_whose_expiry_is_one_millisecond_after_the_date() throws {
        let moduleId = try modulesRepository.registerModule(name: "test")
        let keyValueRepository = SQLKeyValueRepository(dbProvider: dbProvider, moduleId: moduleId)
        let date = Date(unixMilliseconds: 4_102_444_800_000)
        try keyValueRepository.upsert(key: "survivor", value: "value", expiry: .after(Date(unixMilliseconds: 4_102_444_800_001)))
        let eventNotified = expectation(description: "onDataExpired event is NOT notified")
        eventNotified.isInverted = true
        let subscription = modulesRepository.onDataExpired.subscribe { _ in
            eventNotified.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .sessionChange, date: date)
        waitForDefaultTimeout()
        subscription.dispose()
        XCTAssertNotNil(keyValueRepository.getAll().asDictionary()["survivor"])
    }

    // MARK: - Unreadable rows

    func test_getModules_that_hits_corruption_returns_no_modules_and_deletes_the_file() throws {
        try assertStatementDeletesUnreadableFile(writing: storeValueUntilRestart) {
            XCTAssertEqual(SQLModulesRepository(dbProvider: $0).getModules(), [:])
        }
    }

    func test_deleteExpired_that_hits_corruption_notifies_nothing_and_deletes_the_file() throws {
        try assertStatementDeletesUnreadableFile(writing: storeValueUntilRestart) { provider in
            let repository = SQLModulesRepository(dbProvider: provider)
            var notified = false
            let subscription = repository.onDataExpired.subscribe { _ in notified = true }
            repository.deleteExpired(expiry: .restart)
            subscription.dispose()
            XCTAssertFalse(notified)
        }
    }

    func test_registerModule_that_hits_corruption_throws_and_deletes_the_file() throws {
        try assertStatementDeletesUnreadableFile(writing: storeValueUntilRestart) { provider in
            let error = try XCTUnwrapThrownError { try SQLModulesRepository(dbProvider: provider).registerModule(name: "test") }
            XCTAssertEqual(DatabaseHelper.corruptionCode(error), SQLITE_CORRUPT)
        }
    }

    // MARK: - Helpers

    private func storeValueUntilRestart(in provider: DatabaseProviderProtocol) throws {
        let moduleId = try SQLModulesRepository(dbProvider: provider).registerModule(name: "test")
        try SQLKeyValueRepository(dbProvider: provider, moduleId: moduleId).upsert(key: "key", value: "value", expiry: .untilRestart)
    }
}
