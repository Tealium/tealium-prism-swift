//
//  SQLiteOpenHelperTests.swift
//  tealium-prism_Tests
//
//  Created by Tyler Rister on 12/7/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

class SQLiteOpenHelperTests: XCTestCase {
    var config = createMockConfig()
    lazy var openHelper = SQLiteOpenHelper(version: 1,
                                           config: config)

    func test_init_sets_right_url() throws {
        config.databaseName = "database_name"
        guard let url = openHelper.databaseUrl?.absoluteString else {
            XCTFail("Database url is nil")
            return
        }
        let suffix = "/tealium-prism/mock_account/mock_profile/database_name.sqlite3"
        XCTAssertTrue(url.hasSuffix(suffix), "URL \(url) should have suffix \(suffix)")
    }

    func test_prepare_runs_all_functions_in_order() throws {
        let configureExpectation = expectation(description: "onConfigure is called.")
        let createExpectation = expectation(description: "onCreate is called.")
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let mockDatabaseHelper = MockDatabaseHelper(version: 1,
                                                    onCreateCallback: { _ in
            createExpectation.fulfill()
        },
                                                    onConfigureCallback: { _ in
            configureExpectation.fulfill()
        },
                                                    onOpenCallback: { _ in
            onOpenExpectation.fulfill()
        })
        _ = try mockDatabaseHelper.getDatabase()
        wait(for: [configureExpectation, createExpectation, onOpenExpectation],
             timeout: Self.defaultTimeout,
             enforceOrder: true)
    }

    func test_prepare_runs_all_functions_in_order_for_upgrade() throws {
        let configureExpectation = expectation(description: "onConfigure is called.")
        let onCreateExpectation = expectation(description: "onCreate is NEVER called.")
        onCreateExpectation.isInverted = true
        let onUpgradeExpectation = expectation(description: "onUpgrade is called.")
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let connection = try openHelper.getDatabase()
        let mockDatabaseHelper = MockDatabaseHelper(version: 2,
                                                    onUpgradeCallback: { _, oldVersion, newVersion in
            XCTAssertEqual(oldVersion, self.openHelper.version)
            XCTAssertEqual(newVersion, 2)
            onUpgradeExpectation.fulfill()
        },
                                                    onCreateCallback: { _ in
            onCreateExpectation.fulfill()
        },
                                                    onConfigureCallback: { _ in
            configureExpectation.fulfill()
        },
                                                    onOpenCallback: { _ in
            onOpenExpectation.fulfill()
        })
        try mockDatabaseHelper.prepare(database: connection)
        wait(for: [configureExpectation, onUpgradeExpectation, onOpenExpectation, onCreateExpectation],
             timeout: Self.defaultTimeout,
             enforceOrder: true)
    }

    func test_prepare_runs_all_functions_in_order_for_downgrade() throws {
        let configureExpectation = expectation(description: "onConfigure is called.")
        let onCreateExpectation = expectation(description: "onCreate is NEVER called.")
        onCreateExpectation.isInverted = true
        let onUpgradeExpectation = expectation(description: "onUpgrade is NEVER called.")
        onUpgradeExpectation.isInverted = true
        let onDowngradeExpectation = expectation(description: "onDowngrade is called.")
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let connection = try openHelper.getDatabase()
        connection.userVersion = 2
        let mockDatabaseHelper = MockDatabaseHelper(version: 1,
                                                    onUpgradeCallback: { _, _, _ in
            onUpgradeExpectation.fulfill()
        },
                                                    onDowngradeCallback: { _, oldVersion, newVersion in
            XCTAssertEqual(oldVersion, 2)
            XCTAssertEqual(newVersion, 1)
            onDowngradeExpectation.fulfill()
        },
                                                    onCreateCallback: { _ in
            onCreateExpectation.fulfill()
        },
                                                    onConfigureCallback: { _ in
            configureExpectation.fulfill()
        },
                                                    onOpenCallback: { _ in
            onOpenExpectation.fulfill()
        })
        _ = try mockDatabaseHelper.prepare(database: connection)
        wait(for: [configureExpectation, onDowngradeExpectation, onOpenExpectation, onUpgradeExpectation, onCreateExpectation],
             timeout: Self.defaultTimeout,
             enforceOrder: true)
    }

    func test_prepare_only_runs_onCreate_for_fresh_database_with_version_greater_than_one() throws {
        let connection = try Connection(.inMemory)
        let configureExpectation = expectation(description: "onConfigure is called.")
        let onCreateExpectation = expectation(description: "onCreate is called.")
        let onUpgradeExpectation = expectation(description: "onUpgrade is NEVER called.")
        onUpgradeExpectation.isInverted = true
        let onDowngradeExpectation = expectation(description: "onDowngrade is NEVER called.")
        onDowngradeExpectation.isInverted = true
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let mockDatabaseHelper = MockDatabaseHelper(version: 3,
                                                    onUpgradeCallback: { _, _, _ in
            onUpgradeExpectation.fulfill()
        },
                                                    onDowngradeCallback: { _, _, _ in
            onDowngradeExpectation.fulfill()
        },
                                                    onCreateCallback: { _ in
            onCreateExpectation.fulfill()
        },
                                                    onConfigureCallback: { _ in
            configureExpectation.fulfill()
        },
                                                    onOpenCallback: { _ in
            onOpenExpectation.fulfill()
        })
        try mockDatabaseHelper.prepare(database: connection)
        wait(for: [configureExpectation, onCreateExpectation, onOpenExpectation, onUpgradeExpectation, onDowngradeExpectation],
             timeout: Self.defaultTimeout,
             enforceOrder: true)
        XCTAssertEqual(connection.userVersion, 3)
    }

    func test_prepare_skips_schema_callbacks_when_stored_version_matches() throws {
        let connection = try Connection(.inMemory)
        connection.userVersion = 2
        let configureExpectation = expectation(description: "onConfigure is called.")
        let onCreateExpectation = expectation(description: "onCreate is NEVER called.")
        onCreateExpectation.isInverted = true
        let onUpgradeExpectation = expectation(description: "onUpgrade is NEVER called.")
        onUpgradeExpectation.isInverted = true
        let onDowngradeExpectation = expectation(description: "onDowngrade is NEVER called.")
        onDowngradeExpectation.isInverted = true
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let mockDatabaseHelper = MockDatabaseHelper(version: 2,
                                                    onUpgradeCallback: { _, _, _ in
            onUpgradeExpectation.fulfill()
        },
                                                    onDowngradeCallback: { _, _, _ in
            onDowngradeExpectation.fulfill()
        },
                                                    onCreateCallback: { _ in
            onCreateExpectation.fulfill()
        },
                                                    onConfigureCallback: { _ in
            configureExpectation.fulfill()
        },
                                                    onOpenCallback: { _ in
            onOpenExpectation.fulfill()
        })
        try mockDatabaseHelper.prepare(database: connection)
        wait(for: [configureExpectation, onOpenExpectation, onCreateExpectation, onUpgradeExpectation, onDowngradeExpectation],
             timeout: Self.defaultTimeout,
             enforceOrder: true)
    }

    func test_prepare_sets_userVersion_to_target_after_onCreate() throws {
        let connection = try Connection(.inMemory)
        let mockDatabaseHelper = MockDatabaseHelper(version: 5)
        try mockDatabaseHelper.prepare(database: connection)
        XCTAssertEqual(connection.userVersion, 5)
    }

    func test_prepare_sets_userVersion_to_target_after_onUpgrade() throws {
        let connection = try Connection(.inMemory)
        connection.userVersion = 1
        let mockDatabaseHelper = MockDatabaseHelper(version: 4)
        try mockDatabaseHelper.prepare(database: connection)
        XCTAssertEqual(connection.userVersion, 4)
    }

    func test_prepare_throws_when_version_is_less_than_1() {
        let helper = SQLiteOpenHelper(version: 0, config: config)
        XCTAssertThrowsError(try helper.getDatabase()) { error in
            guard let databaseError = error as? DatabaseError,
                  case let .invalidDatabaseVersion(version) = databaseError else {
                return XCTFail("Expected invalidDatabaseVersion error but got \(error)")
            }
            XCTAssertEqual(version, 0)
        }
    }

    func test_prepare_throws_when_onOpen_throws() throws {
        let connection = try openHelper.getDatabase()
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let databaseHelper = MockDatabaseHelper(version: 1,
                                                onOpenCallback: { _ in
            onOpenExpectation.fulfill()
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try databaseHelper.prepare(database: connection))
        waitForDefaultTimeout()
    }

    func test_prepare_rolls_back_schema_changes_and_userVersion_when_onUpgrade_throws() throws {
        let connection = try Connection(.inMemory)
        try ModuleSchema.createTable(database: connection)
        connection.userVersion = 1
        let mockDatabaseHelper = MockDatabaseHelper(version: 2,
                                                    onUpgradeCallback: { connection, _, _ in
            try connection.run(ModuleSchema.table.addColumn(Expression<String>("rollback_column"), defaultValue: "test"))
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try mockDatabaseHelper.prepare(database: connection))
        XCTAssertFalse(try connection.columnExists(column: "rollback_column", in: "module"))
        XCTAssertEqual(connection.userVersion, 1)
    }

    func test_prepare_throws_when_onCreate_throws() {
        let databaseHelper = MockDatabaseHelper(version: 1,
                                                onCreateCallback: { _ in
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try databaseHelper.getDatabase())
    }

    func test_prepare_throws_when_onConfigure_throws() {
        let databaseHelper = MockDatabaseHelper(version: 1,
                                                onConfigureCallback: { _ in
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try databaseHelper.getDatabase())
    }

    func test_prepare_throws_when_onUpgrade_throws() throws {
        let connection = try openHelper.getDatabase()
        let onUpgradeExpectation = expectation(description: "onUpgrade is called.")
        let databaseHelper = MockDatabaseHelper(version: 2,
                                                onUpgradeCallback: { _, _, _ in
            onUpgradeExpectation.fulfill()
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try databaseHelper.prepare(database: connection))
        waitForDefaultTimeout()
    }

    func test_prepare_throws_when_onDowngrade_throws() throws {
        let connection = try openHelper.getDatabase()
        connection.userVersion = 2
        let onDowngradeExpectation = expectation(description: "onDowngrade is called.")
        let databaseHelper = MockDatabaseHelper(version: 1,
                                                onDowngradeCallback: { _, _, _ in
            onDowngradeExpectation.fulfill()
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try databaseHelper.prepare(database: connection))
        waitForDefaultTimeout()
    }

    func test_create_and_delete_database() throws {
        config.databaseName = "test"
        guard let path = openHelper.databaseUrl?.path else {
            XCTFail("Failed to get path for database")
            return
        }
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }
        XCTAssertNoThrow(try openHelper.getDatabase())
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        openHelper.deleteDatabase()
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    func test_database_is_excluded_from_backup() throws {
        config.databaseName = "test"
        _ = try openHelper.getDatabase()
        guard let url = openHelper.databaseUrl else {
            XCTFail("Invalid database url.")
            return
        }
        let isExcludedFromBackup = try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        XCTAssertTrueOptional(isExcludedFromBackup)
        openHelper.deleteDatabase()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}
