//
//  ConnectionTransactionTests.swift
//  tealium-prism_Tests
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

final class ConnectionTransactionTests: XCTestCase {
    private struct BlockError: Error { }

    func test_the_block_is_committed_on_success() throws {
        let connection = try connectionWithTable()
        try connection.transactionIgnoringRollbackError(.immediate) {
            try connection.run("INSERT INTO t VALUES (1)")
        }
        XCTAssertEqual(try connection.scalar("SELECT COUNT(*) FROM t") as? Int64, 1)
    }

    func test_the_transaction_begins_with_the_given_mode() throws {
        for mode in [Connection.TransactionMode.deferred, .immediate, .exclusive] {
            let connection = try connectionWithTable()
            var statements = [String]()
            connection.trace { statements.append($0) }
            try connection.transactionIgnoringRollbackError(mode) { }
            XCTAssertEqual(statements.filter { $0.hasPrefix("BEGIN") }, ["BEGIN \(mode.rawValue) TRANSACTION"])
        }
    }

    func test_the_block_failure_is_rolled_back_and_rethrown() throws {
        let connection = try connectionWithTable()
        XCTAssertThrowsError(try connection.transactionIgnoringRollbackError(.immediate) {
            try connection.run("INSERT INTO t VALUES (1)")
            throw BlockError()
        }) { XCTAssertTrue($0 is BlockError, "\($0)") }
        XCTAssertEqual(try connection.scalar("SELECT COUNT(*) FROM t") as? Int64, 0)
    }

    func test_the_block_error_is_thrown_even_when_the_rollback_fails_too() throws {
        let connection = try connectionWithTable()
        XCTAssertThrowsError(try connection.transactionIgnoringRollbackError(.immediate) {
            // Ending the transaction here makes the helper's own ROLLBACK fail with "no transaction is active".
            try connection.run("ROLLBACK")
            throw BlockError()
        }) { XCTAssertTrue($0 is BlockError, "\($0)") }
    }

    func test_a_failed_commit_is_rolled_back_and_its_error_thrown() throws {
        let connection = try connectionWithTable()
        try connection.run("CREATE TABLE child (parent REFERENCES t(id) DEFERRABLE INITIALLY DEFERRED)")
        try connection.run("PRAGMA foreign_keys = ON")
        XCTAssertThrowsError(try connection.transactionIgnoringRollbackError(.immediate) {
            // A deferred foreign key violation is only found by the COMMIT.
            try connection.run("INSERT INTO child VALUES (99)")
        }) { error in
            XCTAssertEqual((error as? SQLite.Result)?.description.contains("FOREIGN KEY"), true, "\(error)")
        }
        XCTAssertEqual(try connection.scalar("SELECT COUNT(*) FROM child") as? Int64, 0)
    }

    // MARK: - Helpers

    private func connectionWithTable() throws -> Connection {
        let connection = try Connection(.inMemory)
        try connection.run("CREATE TABLE t (id INTEGER PRIMARY KEY)")
        return connection
    }
}
