//
//  SQliteOpenHelperTests.swift
//  tealium-prism_Tests
//
//  Created by Tyler Rister on 14/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

import SQLite
import SQLite3
@testable import TealiumPrism
import XCTest

extension Connection {
    func tableExists(tableName: String) -> Bool {
        let count: Int64? = try? self.scalar(
            "SELECT EXISTS(SELECT name FROM sqlite_master WHERE name = ?)", tableName
        ) as? Int64
        guard let count = count else {
            return false
        }
        return count > 0
    }
    public func columnExists(column: String, in table: String) throws -> Bool {
        let tableInfo = try prepare("PRAGMA table_info(\(table))")
        let columnNames = tableInfo.makeIterator().map { row -> String in
            return row[1] as? String ?? ""
        }
        return columnNames.contains(where: { databaseColumn -> Bool in
            return databaseColumn.caseInsensitiveCompare(column) == ComparisonResult.orderedSame
        })
    }
}

extension SQLite.Connection: Swift.Equatable {
     public static func == (lhs: Connection, rhs: Connection) -> Bool {
         return lhs.handle == rhs.handle
     }
}

class DatabaseHelperTests: XCTestCase {
    var config = createMockConfig()
    lazy var databaseHelper = DatabaseHelper(databaseUrl: nil)
    var accountPath = ""
    var ranSteps = [Int]()

    override func setUp() {
        // Only the test account's folder, not the whole `tealium-prism` one, which unsandboxed apps share on macOS.
        accountPath = (try? TealiumFileManager.getTealiumApplicationFolder().appendingPathComponent(config.account).path) ?? ""
        try? TealiumFileManager.deleteAtPath(path: accountPath)
        config.databaseName = "tealium"
    }

    override func tearDown() {
        try? TealiumFileManager.deleteAtPath(path: accountPath)
    }

    func test_onCreate_creates_tables() throws {
        let connection = try Connection(.inMemory)
        try databaseHelper.onCreate(database: connection)
        XCTAssertTrueOptional(connection.tableExists(tableName: "queue"), "Queue table does not exist")
        XCTAssertTrueOptional(connection.tableExists(tableName: "dispatch"), "Dispatch table does not exist")
        XCTAssertTrueOptional(connection.tableExists(tableName: "module"), "Module table does not exist")
        XCTAssertTrueOptional(connection.tableExists(tableName: "module_storage"), "ModuleStorage table does not exist")
    }

    func test_onUpgrade_updates_the_columns() throws {
        let connection = try Connection(.inMemory)
        let helper = DatabaseHelper(databaseUrl: nil, upgrades: [
            TestUpgrade(targetVersion: 2) { connection in
                try connection.run(ModuleSchema.table.addColumn(Expression<String>("test_new_column"), defaultValue: "test"))
            },
            TestUpgrade(targetVersion: 3) { connection in
                try connection.run(ModuleSchema.table.addColumn(Expression<String>("v3_column"), defaultValue: "test"))
            }
        ])
        try helper.onCreate(database: connection)
        try helper.onUpgrade(database: connection, fromOldVersion: 1, toNewVersion: 3)
        XCTAssertTrueOptional(try connection.columnExists(column: "test_new_column", in: "module"))
        XCTAssertTrueOptional(try connection.columnExists(column: "v3_column", in: "module"))
    }

    func test_onDowngrade_throws_unsupportedDatabaseVersionError_with_the_versions() throws {
        let connection = try Connection(.inMemory)
        XCTAssertThrowsError(try databaseHelper.onDowngrade(database: connection, fromOldVersion: 3, toNewVersion: 1)) { error in
            guard case .newer(stored: 3, current: 1)? = error as? UnsupportedSchemaVersionError else {
                return XCTFail("Expected UnsupportedSchemaVersionError.newer(3, 1) but got \(error)")
            }
        }
    }

    func test_opening_a_newer_file_database_throws_and_leaves_the_file_untouched() throws {
        let databasePath = try stageVersion1Database(config: config, userVersion: 2)
        let helper = DatabaseHelper(databaseUrl: try config.databaseUrl(), version: 1, upgrades: [])
        XCTAssertThrowsError(try helper.getDatabase()) { error in
            guard case .newer(stored: 2, current: 1)? = error as? UnsupportedSchemaVersionError else {
                return XCTFail("Expected UnsupportedSchemaVersionError.newer(2, 1) but got \(error)")
            }
        }
        let state = try storedState(atPath: databasePath)
        XCTAssertEqual(state.userVersion, 2)
        XCTAssertEqual(state.modules, ["marker"])
    }

    func test_onConfigure_sets_the_foreignKeysConstraint() throws {
        let connection = try Connection(.inMemory)
        try databaseHelper.onConfigure(database: connection)
        XCTAssertTrue(connection.foreignKeys)
    }

    // MARK: - Upgrade guards

    /// Steps that record their version in `ranSteps` when they run.
    private func recordingSteps(_ versions: [Int]) -> [DatabaseUpgrade] {
        versions.map { version in
            TestUpgrade(targetVersion: version) { [unowned self] _ in
                self.ranSteps.append(version)
            }
        }
    }

    /// Opens the staged file at `version` with `upgrades` and returns the error that failed the open.
    private func openFailure(version: Int,
                             upgrades: [DatabaseUpgrade],
                             file: StaticString = #filePath,
                             line: UInt = #line) throws -> Error? {
        let helper = DatabaseHelper(databaseUrl: try config.databaseUrl(), version: version, upgrades: upgrades)
        var failure: Error?
        XCTAssertThrows(try helper.getDatabase(), "The open should have failed", file: file, line: line) { error in
            failure = error
        }
        return failure
    }

    /// Asserts that `error` is a broken chain, reported at `version`, whose description is `chain`.
    private func assertBrokenChain(_ error: Error?,
                                   version: Int,
                                   _ chain: String,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) {
        let upgradeError = error as? DatabaseUpgradeError
        XCTAssertTrue(upgradeError?.underlying is DatabaseUpgradeError.BrokenChain, file: file, line: line)
        XCTAssertEqual(upgradeError?.targetVersion, version, file: file, line: line)
        XCTAssertEqual(upgradeError.map { "\($0.underlying)" }, chain, file: file, line: line)
    }

    private func assertFileState(_ databasePath: String,
                                 userVersion: Int64 = 1,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) throws {
        let state = try storedState(atPath: databasePath)
        XCTAssertEqual(state.userVersion, userVersion, file: file, line: line)
        XCTAssertEqual(state.modules, ["marker"], file: file, line: line)
    }

    func test_upgrade_with_a_gap_in_the_chain_fails_before_any_step_runs() throws {
        let databasePath = try stageVersion1Database(config: config)
        let error = try openFailure(version: 4, upgrades: recordingSteps([2, 4]))
        assertBrokenChain(error, version: 3, "Upgrade chain from 1 to 4 is not contiguous: expected [2, 3, 4], registered [2, 4]")
        XCTAssertEqual(ranSteps, [])
        try assertFileState(databasePath)
    }

    func test_upgrade_with_a_duplicate_in_the_chain_fails_before_any_step_runs() throws {
        let databasePath = try stageVersion1Database(config: config)
        let error = try openFailure(version: 3, upgrades: recordingSteps([2, 2, 3]))
        assertBrokenChain(error, version: 2, "Upgrade chain from 1 to 3 is not contiguous: expected [2, 3], registered [2, 2, 3]")
        XCTAssertEqual(ranSteps, [])
        try assertFileState(databasePath)
    }

    func test_upgrade_with_the_chain_in_the_wrong_order_fails_before_any_step_runs() throws {
        let databasePath = try stageVersion1Database(config: config)
        let error = try openFailure(version: 4, upgrades: recordingSteps([3, 2, 4]))
        assertBrokenChain(error, version: 4, "Upgrade chain from 1 to 4 is not contiguous: expected [2, 3, 4], registered [3, 2, 4]")
        XCTAssertEqual(ranSteps, [])
        try assertFileState(databasePath)
    }

    func test_version_bump_without_a_step_fails_with_the_new_version() throws {
        let databasePath = try stageVersion1Database(config: config)
        let error = try openFailure(version: 2, upgrades: [])
        assertBrokenChain(error, version: 2, "Upgrade chain from 1 to 2 is not contiguous: expected [2], registered []")
        try assertFileState(databasePath)
    }

    func test_throwing_step_fails_with_its_version_and_error_and_rolls_back() throws {
        let databasePath = try stageVersion1Database(config: config)
        let error = try openFailure(version: 3, upgrades: [
            TestUpgrade(targetVersion: 2) { [unowned self] database in
                self.ranSteps.append(2)
                try database.run("INSERT INTO module (name) VALUES ('from_step_2')")
            },
            TestUpgrade(targetVersion: 3) { [unowned self] _ in
                self.ranSteps.append(3)
                throw StepError()
            }
        ])
        guard let upgradeError = error as? DatabaseUpgradeError else {
            return XCTFail("Expected a DatabaseUpgradeError, got \(String(describing: error))")
        }
        XCTAssertEqual(upgradeError.targetVersion, 3)
        XCTAssertTrue(upgradeError.underlying is StepError, "Expected StepError, got \(upgradeError.underlying)")
        XCTAssertEqual(ranSteps, [2, 3])
        try assertFileState(databasePath)
    }

    func test_stored_version_below_the_minimum_fails_before_the_chain_check_and_any_step() throws {
        let databasePath = try stageVersion1Database(config: config, userVersion: -1)
        // The chain is broken too, so the minimum check must come first to be the one reported.
        let error = try openFailure(version: 3, upgrades: recordingSteps([3]))
        guard case .belowMinimum(stored: -1)? = error as? UnsupportedSchemaVersionError else {
            return XCTFail("Expected UnsupportedSchemaVersionError.belowMinimum(-1), got \(String(describing: error))")
        }
        XCTAssertEqual(ranSteps, [])
        try assertFileState(databasePath, userVersion: -1)
    }

    func test_upgrade_runs_every_step_in_order_and_stamps_the_new_version() throws {
        let databasePath = try stageVersion1Database(config: config)
        var connection: Connection? = try DatabaseHelper(databaseUrl: try config.databaseUrl(),
                                                         version: 3,
                                                         upgrades: recordingSteps([2, 3])).getDatabase()
        XCTAssertEqual(connection?.userVersion.map(Int.init), 3)
        connection = nil
        XCTAssertEqual(ranSteps, [2, 3])
        try assertFileState(databasePath, userVersion: 3)
    }
}
