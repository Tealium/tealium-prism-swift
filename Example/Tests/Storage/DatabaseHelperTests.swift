//
//  SQliteOpenHelperTests.swift
//  tealium-swift_Tests
//
//  Created by Tyler Rister on 14/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

import SQLite
import SQLite3
@testable import TealiumSwift
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

extension Connection: Equatable {
     public static func == (lhs: Connection, rhs: Connection) -> Bool {
         return lhs.handle == rhs.handle
     }
}

class DatabaseHelperTests: XCTestCase {
    var databaseHelper: DatabaseHelper?
    let testCoreSettings = CoreSettings(coreDictionary: ["account": "test", "profile": "test"])

    override func setUp() {
        self.databaseHelper = try? DatabaseHelper(databaseName: "test_database", coreSettings: self.testCoreSettings)
    }

    override func tearDown() {
        self.databaseHelper?.deleteDatabase()
    }

    func test_tables_created() {
        let connection = databaseHelper?.getDatabase()
        XCTAssertTrueOptional(connection?.tableExists(tableName: "queue"), "Queue table does not exist")
        XCTAssertTrueOptional(connection?.tableExists(tableName: "dispatch"), "Dispatch table does not exist")
        XCTAssertTrueOptional(connection?.tableExists(tableName: "dispatcher"), "Dispatcher table does not exist")
        XCTAssertTrueOptional(connection?.tableExists(tableName: "module"), "Module table does not exist")
        XCTAssertTrueOptional(connection?.tableExists(tableName: "module_storage"), "ModuleStorage table does not exist")
    }

    func test_OnUpgrade_persists() {
        DatabaseHelper.databaseUpgrades = [
            DatabaseUpgrade(version: 2, upgrade: { connection in
                try connection.run(ModuleSchema.table.addColumn(Expression<String>("test_new_column"), defaultValue: "test"))
            }),
            DatabaseUpgrade(version: 3, upgrade: { connection in
                try connection.run(ModuleSchema.table.addColumn(Expression<String>("v3_column"), defaultValue: "test"))
            })
        ]
        DatabaseHelper.DATABASE_VERSION = 3
        self.databaseHelper?.closeDatabase()
        self.databaseHelper = try? DatabaseHelper(databaseName: "test_database", coreSettings: self.testCoreSettings)
        guard let newDatabase = self.databaseHelper?.getDatabase() else {
            XCTFail("Failed to get new database.")
            return
        }
        XCTAssertTrueOptional(try newDatabase.columnExists(column: "test_new_column", in: "module"))
        XCTAssertTrueOptional(try newDatabase.columnExists(column: "v3_column", in: "module"))
        XCTAssertEqual(newDatabase.userVersion, 3)
    }

    func test_onDowngrade_recreates_database() {
        DatabaseHelper.databaseUpgrades = [
            DatabaseUpgrade(version: 2, upgrade: { connection in
                try connection.run(ModuleSchema.table.addColumn(Expression<String>("test_new_column"), defaultValue: "test"))
            }),
            DatabaseUpgrade(version: 3, upgrade: { connection in
                try connection.run(ModuleSchema.table.addColumn(Expression<String>("v3_column"), defaultValue: "test"))
            })
        ]
        DatabaseHelper.DATABASE_VERSION = 3
        self.databaseHelper = try? DatabaseHelper(databaseName: "test_database", coreSettings: self.testCoreSettings)
        XCTAssertTrueOptional(try? databaseHelper?.getDatabase()?.columnExists(column: "test_new_column", in: "module"))
        XCTAssertTrueOptional(try? databaseHelper?.getDatabase()?.columnExists(column: "v3_column", in: "module"))
        DatabaseHelper.DATABASE_VERSION = 1
        self.databaseHelper = try? DatabaseHelper(databaseName: "test_database", coreSettings: self.testCoreSettings)
        XCTAssertFalseOptional(try? databaseHelper?.getDatabase()?.columnExists(column: "test_new_column", in: "module"))
        XCTAssertFalseOptional(try? databaseHelper?.getDatabase()?.columnExists(column: "v3_column", in: "module"))
    }

    func test_getDatabase_only_creates_connection_once() {
        let initialDatabase = databaseHelper?.getDatabase()
        XCTAssertNotNil(initialDatabase)
        let secondDatabase = databaseHelper?.getDatabase()
        XCTAssertNotNil(secondDatabase)
        XCTAssertEqual(initialDatabase, secondDatabase)
    }

    // This test makes sure that if for some reason opening a connection fails, that it reverts to an in memory database.
    // This gets tested by setting the database url to nil so connection fails to create a file at an empty path.
    func test_getDatabase_creates_in_memory_on_error() {
        guard let initialDatabase = databaseHelper?.getDatabase() else {
            XCTFail("Could not get initial database.")
            return
        }
        XCTAssertNotEqual(initialDatabase.description, "")
        let backupUrl = databaseHelper?.databaseUrl
        let backupDatabase = databaseHelper?.database
        databaseHelper?.databaseUrl = nil
        databaseHelper?.database = nil
        let database = databaseHelper?.getDatabase()
        XCTAssertNotNil(database)
        XCTAssertEqual(database?.description, "")
        databaseHelper?.databaseUrl = backupUrl
        databaseHelper?.database = backupDatabase
    }

    func test_onUpgrade_fail_does_not_return_database() {
        guard let database = databaseHelper?.getDatabase() else {
            XCTFail("Could not get database.")
            return
        }
        XCTAssertEqual(database.userVersion, 1)
        DatabaseHelper.databaseUpgrades = [
            DatabaseUpgrade(version: 2, upgrade: { _ in
                try database.run("INVALID SQL QUERY;")
            })
        ]
        DatabaseHelper.DATABASE_VERSION = 2
        let otherDatabase = try? DatabaseHelper(databaseName: "test_database", coreSettings: self.testCoreSettings)
        XCTAssertNil(otherDatabase)
    }

    func test_onCreate_throws_if_called_again() {
        guard let database = databaseHelper?.getDatabase() else {
            XCTFail("Failed to get database.")
            return
        }
        XCTAssertThrowsError(try databaseHelper?.onCreate(database: database))
    }

    func test_database_is_excluded_from_backup() {
        guard let url = databaseHelper?.databaseUrl else {
            XCTFail("Invalid database url.")
            return
        }
        let isExcludedFromBackup = try? url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        XCTAssertTrueOptional(isExcludedFromBackup)
    }
}
