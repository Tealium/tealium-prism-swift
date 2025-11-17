//
//  AppDataModuleTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 18/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class AppDataModuleTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    lazy var dataStoreProvider = ModuleStoreProvider(databaseProvider: dbProvider, modulesRepository: SQLModulesRepository(dbProvider: dbProvider))
    let mockLogger = MockLogger()
    var appDataModule: AppDataModule!
    var mockInfo = [
        "CFBundleName": "TestApp",
        "CFBundleIdentifier": "com.example.testapp",
        "CFBundleShortVersionString": "1.2.3",
        "CFBundleVersion": "100"
    ]
    var mockBundle: Bundle {
        MockBundle(infoDictionary: mockInfo)
    }
    let dispatchContext = DispatchContext(source: .application, initialData: [:])

    override func setUpWithError() throws {
        let dataStore = try dataStoreProvider.getModuleStore(name: AppDataModule.moduleType)
        appDataModule = AppDataModule(dataStore: dataStore, bundle: mockBundle, logger: mockLogger)
    }

    func test_collect_returns_expected_data() {
        let appData = appDataModule.collect(dispatchContext)
        XCTAssertEqual(appData.get(key: TealiumDataKey.appBuild), "100")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appName), "TestApp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appRDNS), "com.example.testapp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appVersion), "1.2.3")
        XCTAssertNotNil(appData.get(key: TealiumDataKey.appUUID, as: String.self))
    }

    func test_collect_returns_expected_data_when_some_values_are_absent() throws {
        mockInfo.removeValue(forKey: "CFBundleShortVersionString")
        mockInfo.removeValue(forKey: "CFBundleVersion")
        let dataStore2 = try dataStoreProvider.getModuleStore(name: AppDataModule.moduleType)
        let newAppDataModule = AppDataModule(dataStore: dataStore2, bundle: mockBundle, logger: mockLogger)
        let appData = newAppDataModule.collect(dispatchContext)
        XCTAssertEqual(appData.get(key: TealiumDataKey.appBuild), NSNull())
        XCTAssertEqual(appData.get(key: TealiumDataKey.appName), "TestApp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appRDNS), "com.example.testapp")
        XCTAssertEqual(appData.get(key: TealiumDataKey.appVersion), NSNull())
        XCTAssertNotNil(appData.get(key: TealiumDataKey.appUUID, as: String.self))
    }

    func test_app_uuid_is_generated_and_persisted() throws {
        let firstCollect = appDataModule.collect(dispatchContext)
        let firstUUID: String? = firstCollect.get(key: TealiumDataKey.appUUID)
        guard let firstUUID else {
            XCTFail("Failed to retrieve generated app UUID from first collection")
            return
        }
        XCTAssertFalse(firstUUID.isEmpty)

        // Create a new module instance to simulate app restart
        let dataStore2 = try dataStoreProvider.getModuleStore(name: AppDataModule.moduleType)
        let newAppDataModule = AppDataModule(dataStore: dataStore2, bundle: mockBundle, logger: mockLogger)
        let secondCollect = newAppDataModule.collect(dispatchContext)
        let secondUUID: String? = secondCollect.get(key: TealiumDataKey.appUUID)
        XCTAssertEqual(firstUUID, secondUUID, "App UUID should persist across module instances")
    }

    func test_app_uuid_generation_logs_error_on_datastore_failure() throws {
        let errorLogged = expectation(description: "Error logged")
        // Create a mock data store that fails on edit operations
        let failingDataStore = FailingMockDataStore()
        let logger = MockLogger()
        let moduleWithFailingStore = AppDataModule(dataStore: failingDataStore, bundle: mockBundle, logger: logger)

        logger.handler.onLogged.subscribeOnce { logEvent in
            guard logEvent.level == .error, logEvent.category == AppDataModule.moduleType else {
                XCTFail("Invalid log event")
                return
            }
            XCTAssertTrue(logEvent.message.contains("Error writing app UUID to data store"))
            errorLogged.fulfill()
        }
        let appData = moduleWithFailingStore.collect(dispatchContext)
        let uuid = appData.get(key: TealiumDataKey.appUUID, as: String.self)

        // UUID should still be generated even if storage fails
        XCTAssertNotNil(uuid)
        waitForExpectations(timeout: 1.0)
    }

    func test_the_module_id_is_correct() {
        XCTAssertNotNil(dataStoreProvider.modulesRepository.getModules()[AppDataModule.moduleType])
    }
}
