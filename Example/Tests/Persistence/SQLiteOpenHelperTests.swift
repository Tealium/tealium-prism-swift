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
    let openHelper = SQLiteOpenHelper(databaseName: nil,
                                      version: 1,
                                      config: mockConfig)

    func test_prepare_runs_all_functions_in_order() throws {
        let configureExpectation = expectation(description: "onConfigure is called.")
        let createExpectation = expectation(description: "onCreate is called.")
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let mockDatabaseHelper = MockDatabaseHelper(databaseName: nil,
                                                    version: 1,
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
             timeout: 1.0,
             enforceOrder: true)
    }

    func test_prepare_runs_all_functions_in_order_for_upgrade() throws {
        let configureExpectation = expectation(description: "onConfigure is called.")
        let onCreateExpectation = expectation(description: "onCreate is NEVER called.")
        onCreateExpectation.isInverted = true
        let onUpgradeExpectation = expectation(description: "onUpgrade is called.")
        let onOpenExpectation = expectation(description: "onOpen is called.")
        let connection = try openHelper.getDatabase()
        let mockDatabaseHelper = MockDatabaseHelper(databaseName: nil,
                                                    version: 2,
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
             timeout: 1.0,
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
        let mockDatabaseHelper = MockDatabaseHelper(databaseName: nil,
                                                    version: 0,
                                                    onUpgradeCallback: { _, _, _ in
            onUpgradeExpectation.fulfill()
        },
                                                    onDowngradeCallback: { _, oldVersion, newVersion in
            XCTAssertEqual(oldVersion, self.openHelper.version)
            XCTAssertEqual(newVersion, 0)
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
             timeout: 1.0,
             enforceOrder: true)
    }

    func test_prepare_throws_when_onCreate_throws() {
        let databaseHelper = MockDatabaseHelper(databaseName: nil,
                                                version: 1,
                                                onCreateCallback: { _ in
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try databaseHelper.getDatabase())
    }

    func test_prepare_throws_when_onConfigure_throws() {
        let databaseHelper = MockDatabaseHelper(databaseName: nil,
                                                version: 1,
                                                onConfigureCallback: { _ in
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try databaseHelper.getDatabase())
    }

    func test_prepare_throws_when_onUpgrade_throws() throws {
        let connection = try openHelper.getDatabase()
        let onUpgradeExpectation = expectation(description: "onUpgrade is called.")
        let databaseHelper = MockDatabaseHelper(databaseName: nil,
                                                version: 2,
                                                onUpgradeCallback: { _, _, _ in
            onUpgradeExpectation.fulfill()
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try databaseHelper.prepare(database: connection))
        waitForExpectations(timeout: 1.0)
    }

    func test_prepare_throws_when_onDowngrade_throws() throws {
        let connection = try openHelper.getDatabase()
        let onDowngradeExpectation = expectation(description: "onDowngrade is called.")
        let databaseHelper = MockDatabaseHelper(databaseName: nil,
                                                version: 0,
                                                onDowngradeCallback: { _, _, _ in
            onDowngradeExpectation.fulfill()
            throw NSError(domain: "Test Error", code: 1)
        })
        XCTAssertThrowsError(try databaseHelper.prepare(database: connection))
        waitForExpectations(timeout: 1.0)
    }

    func test_create_and_delete_database() throws {
        let sqlOpenHelper = SQLiteOpenHelper(databaseName: "test", version: 1, config: mockConfig)
        guard let path = sqlOpenHelper.databaseUrl?.path else {
            XCTFail("Failed to get path for database")
            return
        }
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }
        XCTAssertNoThrow(try sqlOpenHelper.getDatabase())
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        sqlOpenHelper.deleteDatabase()
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    func test_database_is_excluded_from_backup() throws {
        let sqlOpenHelper = SQLiteOpenHelper(databaseName: "test", version: 1, config: mockConfig)
        _ = try sqlOpenHelper.getDatabase()
        guard let url = sqlOpenHelper.databaseUrl else {
            XCTFail("Invalid database url.")
            return
        }
        let isExcludedFromBackup = try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        XCTAssertTrueOptional(isExcludedFromBackup)
        sqlOpenHelper.deleteDatabase()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}
