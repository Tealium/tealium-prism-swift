//
//  ModuleStoreProviderTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 15/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ModuleStoreProviderTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    func test_getModuleStore_automatically_registers_module() {
        let storeProvider = ModuleStoreProvider(databaseProvider: dbProvider, modulesRepository: SQLModulesRepository(dbProvider: dbProvider))
        let store = XCTAssertNoThrowReturn(try storeProvider.getModuleStore(name: "test"))
        XCTAssertNotNil(store)
        let allModules = storeProvider.modulesRepository.getModules()
        XCTAssertNotNil(allModules["test"])
    }

    func test_getModuleStore_filters_expiredData_for_correct_module() {
        let storeProvider = ModuleStoreProvider(databaseProvider: dbProvider, modulesRepository: MockModulesRepository())
        let store = XCTAssertNoThrowReturn(try storeProvider.getModuleStore(name: "test"))
        XCTAssertNotNil(store)
        let onDataRemovedNotified = expectation(description: "onDataRemoved is notified")
        store?.onDataRemoved.subscribeOnce { dataRemoved in
            XCTAssertTrue(dataRemoved.contains("key1"))
            XCTAssertFalse(dataRemoved.contains("key2"))
            onDataRemovedNotified.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_getModuleStore_returns_cached_store_when_available() {
        let storeProvider = ModuleStoreProvider(databaseProvider: dbProvider, modulesRepository: MockModulesRepository())
        let store = XCTAssertNoThrowReturn(try storeProvider.getModuleStore(name: "test"))
        XCTAssertNotNil(store)
        let store2 = XCTAssertNoThrowReturn(try storeProvider.getModuleStore(name: "test"))
        XCTAssertNotNil(store2)
        XCTAssertIdentical(store, store2)
    }
}
