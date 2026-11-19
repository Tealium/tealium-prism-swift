//
//  SQLiteTestSupport.swift
//  tealium-prism_Tests
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
import SQLite3
@testable import TealiumPrism
import XCTest

// Swift doesn't import these extended result codes (composite macros in sqlite3.h), so they are defined here as the header does.
let SQLITE_IOERR_READ = SQLITE_IOERR | (1 << 8)
let SQLITE_READONLY_DBMOVED = SQLITE_READONLY | (4 << 8)
let SQLITE_CORRUPT_VTAB = SQLITE_CORRUPT | (1 << 8)
let SQLITE_CORRUPT_SEQUENCE = SQLITE_CORRUPT | (2 << 8)
let SQLITE_CORRUPT_INDEX = SQLITE_CORRUPT | (3 << 8)

extension XCTestCase {
    /// The database file at `path` and its sidecars, the database file first.
    func databaseFiles(atPath path: String) -> [String] {
        [path] + SQLiteOpenHelper.sidecarSuffixes.map { path + $0 }
    }

    /// The size of the -wal file next to the database file at `path`. Throws when there is no -wal file.
    func walSize(ofDatabaseAt path: String) throws -> Int {
        try XCTUnwrap(try FileManager.default.attributesOfItem(atPath: path + "-wal")[.size] as? Int, "No size for \(path)-wal")
    }

    /// The result of `PRAGMA integrity_check` on the database file at `path`, read with a fresh connection: "ok" when sound.
    func integrityCheck(ofDatabaseAt path: String) throws -> String? {
        try Connection(path, readonly: true).scalar("PRAGMA integrity_check") as? String
    }
}

/// A SQLite error with `code` and the message "injected", as a statement throws it.
func injectedSQLiteError(code: Int32) -> SQLite.Result {
    SQLite.Result.error(message: "injected", code: code, statement: nil)
}

extension SQLite.Result {
    /// The code as SQLite reported it: the extended code when this is an `.extendedError`, the primary code otherwise.
    var resultCode: Int32 {
        switch self {
        case let .error(_, code, _):
            code
        case let .extendedError(_, code, _):
            code
        }
    }
}

extension Connection {
    /// Adds the SQL function `fail(code)` and turns on extended result codes: a statement that calls it fails with that SQLite result
    /// code, extended codes included, and the message "injected". The function holds no reference to the connection.
    ///
    /// - Returns: this connection, so that it can be handed on without keeping a reference to it.
    func addingFailFunction() -> Connection {
        usesExtendedErrorCodes = true
        let result = sqlite3_create_function_v2(handle, "fail", 1, SQLITE_UTF8, nil, { context, _, arguments in
            sqlite3_result_error(context, "injected", -1)
            sqlite3_result_error_code(context, sqlite3_value_int(arguments?[0]))
        }, nil, nil, nil)
        XCTAssertEqual(result, SQLITE_OK, "Could not add the fail function")
        return self
    }
}
