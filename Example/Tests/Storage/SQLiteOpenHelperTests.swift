//
//  SQLiteOpenHelperTests.swift
//  tealium-swift_Tests
//
//  Created by Tyler Rister on 12/7/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumSwift
import XCTest

class SQLiteOpenHelperTests: XCTestCase {

    var databaseHelper: DatabaseHelper?

    override func setUp() {
        self.databaseHelper = try? DatabaseHelper(databaseName: "test_database",
                                                  coreSettings: CoreSettings(coreDictionary: ["account": "test", "profile": "test"]))
    }

    override func tearDown() {
        self.databaseHelper?.deleteDatabase()
    }

    func test_prepare_runs_all_functions_in_order_for_create() {
        let configureExpectation = expectation(description: "onConfigure is called.")
        let createExpectation = expectation(description: "onCreate is called.")
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "mock_database",
                                                         version: 2,
                                                         onCreateCallback: { _ in
            createExpectation.fulfill()
        },
                                                         onConfigureCallback: { _ in
            configureExpectation.fulfill()
        },
                                                         onOpenCallback: { _ in
            onOpenExpectation.fulfill()
        })
        wait(for: [configureExpectation, createExpectation, onOpenExpectation], timeout: 3.0, enforceOrder: true)
        mockDatabaseHelper?.deleteDatabase()
    }

    func test_prepare_runs_all_functions_in_order_for_upgrade() {
        let onCreateExpectation = expectation(description: "onCreate is called.")
        let onUpgradeExpectation = expectation(description: "onUpgrade is called.")
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "mock_database",
                                                         version: 2,
                                                         onUpgradeCallback: { _, _, _ in
            onUpgradeExpectation.fulfill()
        },
                                                         onCreateCallback: { _ in
            onCreateExpectation.fulfill()
        },
                                                         onOpenCallback: { _ in
            onOpenExpectation.fulfill()
        })
        wait(for: [onCreateExpectation, onUpgradeExpectation, onOpenExpectation], timeout: 3.0, enforceOrder: true)
        mockDatabaseHelper?.deleteDatabase()
    }

    func test_prepare_runs_all_functions_in_order_for_downgrade() {
        let onDowngradeExpectation = expectation(description: "onDowngrade is called.")
        let onOpenCalled = expectation(description: "onOpen is called.")
        var mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "mock_database", version: 2)
        mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "mock_database",
                                                     version: 1,
                                                     onDowngradeCallback: { _, _, _ in
            onDowngradeExpectation.fulfill()
        },
                                                     onOpenCallback: { _ in
            onOpenCalled.fulfill()
        })
        wait(for: [onDowngradeExpectation, onOpenCalled], timeout: 3.0, enforceOrder: true)
        mockDatabaseHelper?.deleteDatabase()
    }

    func test_onCreate_called_when_dowgrade_throws_UnsupportedDowgrade() {
        let createExpectation = expectation(description: "onCreate is called.")
        var mockDatabase = try? MockDatabaseHelper(databaseName: "mock_database", version: 2)
        mockDatabase = try? MockDatabaseHelper(databaseName: "mock_database",
                                               version: 1,
                                               onDowngradeCallback: { _, _, _ in
            throw DatabaseErrors.unsupportedDowgrade
        },
                                               onCreateCallback: { _ in
            createExpectation.fulfill()
        })
        wait(for: [createExpectation], timeout: 3.0)
        mockDatabase?.deleteDatabase()
    }

    func test_onCreate_throws_returns_nil() {
        let mockDatabase = try? MockDatabaseHelper(databaseName: "mock_database", version: 1, onCreateCallback: { _ in
            throw NSError(domain: "Fake Error", code: 1)
        })
        XCTAssertNil(mockDatabase)
    }

    func test_onUpgrade_gets_called() {
        let onCreateCalled = expectation(description: "onCreate is called for initial version.")
        let onUpgradeCalled = expectation(description: "onUpgrade called with newVersion of 2")
        _ = try? MockDatabaseHelper(databaseName: "database_to_upgrade", version: 1, onCreateCallback: { _ in
            onCreateCalled.fulfill()
        })
        let mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "database_to_upgrade", version: 2, onUpgradeCallback: { _, _, newVersion in
            if newVersion == 2 {
                onUpgradeCalled.fulfill()
            }
        })
        wait(for: [onCreateCalled, onUpgradeCalled], timeout: 3.0, enforceOrder: true)
        mockDatabaseHelper?.deleteDatabase()
    }

    func test_onDowngrade_gets_called() {
        let onCreateCalled = expectation(description: "onCreate is called for initial version.")
        let onUpgradeCalled = expectation(description: "onUpgrade called with newVersion of 2")
        let onDowngradeCalled = expectation(description: "onDowngrade called with newVersion of 1, oldVersion of 2")
        _ = try? MockDatabaseHelper(databaseName: "database_to_downgrade", version: 1, onCreateCallback: { _ in
            onCreateCalled.fulfill()
        })
        _ = try? MockDatabaseHelper(databaseName: "database_to_downgrade", version: 2, onUpgradeCallback: { _, _, newVersion in
            if newVersion == 2 {
                onUpgradeCalled.fulfill()
            }
        })
        let mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "database_to_downgrade", version: 1, onDowngradeCallback: { _, oldVersion, newVersion in
            if oldVersion == 2 && newVersion == 1 {
                onDowngradeCalled.fulfill()
            }
        })
        wait(for: [onCreateCalled, onUpgradeCalled, onDowngradeCalled], timeout: 3.0, enforceOrder: true)
        mockDatabaseHelper?.deleteDatabase()
    }

    func test_delete_database() {
        guard let path = TealiumFileManager.getApplicationFilePath(for: "test", profile: "test", fileName: "test_database.sqlite3") else {
            XCTFail("Failed to get path for database")
            return
        }
        XCTAssertTrueOptional(FileManager.default.fileExists(atPath: path))
        self.databaseHelper?.deleteDatabase()
        XCTAssertFalseOptional(FileManager.default.fileExists(atPath: path))
        XCTAssertNil(self.databaseHelper?.database)
    }

    func test_database_created() {
        let path = TealiumFileManager.getApplicationFilePath(for: "test", profile: "test", fileName: "test_database.sqlite3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path ?? ""))
    }

    func test_prepare_throws_when_onCreate_throws() {
        guard let mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "test_database", version: 1) else {
            XCTFail("MockDatabaseHelper failed to initialize")
            return
        }
        mockDatabaseHelper.onCreateCallback = { _ in
            throw NSError(domain: "", code: 1)
        }
        mockDatabaseHelper.getDatabase()?.userVersion = UserVersion(Int(0))
        XCTAssertThrowsError(try mockDatabaseHelper.prepare())
    }

    func test_prepare_throws_when_onConfigure_throws() {
        guard let mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "test_database", version: 1) else {
            XCTFail("MockDatabaseHelper failed to initialize")
            return
        }
        mockDatabaseHelper.onConfigureCallback = { _ in
            throw NSError(domain: "", code: 1)
        }
        mockDatabaseHelper.getDatabase()?.userVersion = UserVersion(Int(0))
        XCTAssertThrowsError(try mockDatabaseHelper.prepare())
    }

    func test_prepare_throws_when_onUpgrade_throws() {
        guard let mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "test_database", version: 1) else {
            XCTFail("MockDatabaseHelper failed to initialize")
            return
        }
        mockDatabaseHelper.onUpgradeCallback = { _, _, _ in
            throw NSError(domain: "", code: 1)
        }
        mockDatabaseHelper.version = 2
        XCTAssertThrowsError(try mockDatabaseHelper.prepare())
    }

    func test_prepare_throws_when_onDowngrade_throws() {
        guard let mockDatabaseHelper = try? MockDatabaseHelper(databaseName: "test_database", version: 1) else {
            XCTFail("MockDatabaseHelper failed to initialize")
            return
        }
        mockDatabaseHelper.onDowngradeCallback = { _, _, _ in
            throw NSError(domain: "", code: 1)
        }
        mockDatabaseHelper.getDatabase()?.userVersion = UserVersion(2)
        mockDatabaseHelper.version = 1
        XCTAssertThrowsError(try mockDatabaseHelper.prepare())
    }
}
