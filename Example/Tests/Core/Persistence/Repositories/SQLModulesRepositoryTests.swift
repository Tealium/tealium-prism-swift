//
//  SQLModulesRepositoryTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 15/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
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
        guard let expiredDate = Date().addSeconds(-1) else {
            throw UnexpectedNilError(expected: "Date \(Date())")
        }
        try keyValueRepository1.upsert(key: "expired", value: "value", expiry: .after(expiredDate))
        try keyValueRepository1.upsert(key: "restart", value: "value", expiry: .untilRestart)
        try keyValueRepository1.upsert(key: "session", value: "value", expiry: .session)
        try keyValueRepository1.upsert(key: "non-expired", value: "value", expiry: .afterCustom(unit: .days, value: 1))
        try keyValueRepository1.upsert(key: "forever", value: "value", expiry: .forever)
        try keyValueRepository2.upsert(key: "expired", value: "value", expiry: .after(expiredDate))
        try keyValueRepository2.upsert(key: "restart", value: "value", expiry: .untilRestart)
        try keyValueRepository2.upsert(key: "session", value: "value", expiry: .session)
        try keyValueRepository2.upsert(key: "non-expired", value: "value", expiry: .afterCustom(unit: .days, value: 1))
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
        try keyValueRepository.upsert(key: "non-expired", value: "value", expiry: .afterCustom(unit: .days, value: 1))
        let eventNotified = expectation(description: "onDataExpired event is NOT notified")
        eventNotified.isInverted = true
        let subscription = modulesRepository.onDataExpired.subscribe { _ in
            eventNotified.fulfill()
        }
        modulesRepository.deleteExpired(expiry: .restart)
        waitForDefaultTimeout()
        subscription.dispose()
    }
}
