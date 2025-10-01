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
    lazy var databaseHelper = DatabaseHelper(config: mockConfig)

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
        try databaseHelper.onCreate(database: connection)
        DatabaseHelper.databaseUpgrades = [
            DatabaseUpgrade(version: 2, upgrade: { connection in
                try connection.run(ModuleSchema.table.addColumn(Expression<String>("test_new_column"), defaultValue: "test"))
            }),
            DatabaseUpgrade(version: 3, upgrade: { connection in
                try connection.run(ModuleSchema.table.addColumn(Expression<String>("v3_column"), defaultValue: "test"))
            })
        ]
        try databaseHelper.onUpgrade(database: connection, fromOldVersion: 1, toNewVersion: 3)
        XCTAssertTrueOptional(try connection.columnExists(column: "test_new_column", in: "module"))
        XCTAssertTrueOptional(try connection.columnExists(column: "v3_column", in: "module"))
        XCTAssertEqual(connection.userVersion, 3)
    }

    func test_onDowngrade_recreates_database() throws {
        let connection = try Connection(.inMemory)
        XCTAssertThrowsError(try databaseHelper.onDowngrade(database: connection, fromOldVersion: 3, toNewVersion: 1)) { error in
            XCTAssertEqual(DatabaseErrors.unsupportedDowngrade, error as? DatabaseErrors)
        }
    }

    func test_onConfigure_sets_the_foreigKeysConstraint() throws {
        let connection = try Connection(.inMemory)
        try databaseHelper.onConfigure(database: connection)
        XCTAssertTrue(connection.foreignKeys)
    }
}
