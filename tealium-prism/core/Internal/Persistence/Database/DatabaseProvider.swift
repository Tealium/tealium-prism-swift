//
//  DatabaseProvider.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

public protocol DatabaseProviderProtocol {
    var database: Connection { get }

    /// Folds the write-ahead log back into the main database file and waits for readers to leave it,
    /// so the next write starts again from the beginning of the `-wal` file.
    ///
    /// Has a default implementation so existing conformances (including test doubles) need not
    /// implement it, and so it is a harmless no-op when the database is not in WAL mode.
    ///
    /// - Returns: The row `wal_checkpoint` reports: `busy` is `true` when the checkpoint could not
    ///   complete because another connection still held the log, `log` is the number of frames in the
    ///   log and `checkpointed` the number folded back into the database.
    /// - Throws: The SQLite error if the pragma cannot be prepared or run.
    @discardableResult
    func checkpoint() throws -> (busy: Bool, log: Int, checkpointed: Int)
}

public extension DatabaseProviderProtocol {
    /// An optimization: folds the WAL data into the main database file at sensible points, instead of
    /// waiting for the automatic checkpoint or for the next launch to do it on open. The connection is
    /// held for the process lifetime and SQLite.swift only closes it in `deinit`, which does not run
    /// when the app is killed.
    ///
    /// Strictly durability-positive: `RESTART` moves committed frames INTO the main database and
    /// only lets the next writer restart the log once every frame is there, so nothing is discarded.
    ///
    /// `RESTART` rather than `TRUNCATE`, for parity with Android. The `-wal` file is kept at its
    /// working size and overwritten from the start by the next writer, which is cheaper than
    /// growing it again from zero. It stays bounded: `journal_size_limit` cuts it back to the limit
    /// at that next reset.
    @discardableResult
    func checkpoint() throws -> (busy: Bool, log: Int, checkpointed: Int) {
        // Same as SQLite.swift's `walCheckpoint()` helper, which would replace this, but it is only
        // on master; the latest tagged release does not have it and the pod pins ~> 0.15.0.
        let statement = try database.prepare("PRAGMA wal_checkpoint(RESTART)")
        _ = try statement.step()
        let busy: Int64 = statement.row[0]
        let log: Int64 = statement.row[1]
        let checkpointed: Int64 = statement.row[2]
        return (busy != 0, Int(log), Int(checkpointed))
    }
}

public class DatabaseProvider: DatabaseProviderProtocol {
    public let database: Connection

    init(config: TealiumConfig, logger: LoggerProtocol? = nil) throws {
        database = try Self.getPersistentDatabase(config: config, logger: logger) ?? Self.getInMemoryDatabase()
    }

    static func getPersistentDatabase(config: TealiumConfig, logger: LoggerProtocol? = nil) -> Connection? {
        let helper = DatabaseHelper(config: config, logger: logger)
        do {
            return try helper.getDatabase()
        } catch DatabaseError.unsupportedDowngrade {
            helper.deleteDatabase()
            return try? helper.getDatabase()
        } catch {
            return nil
        }
    }

    static func getInMemoryDatabase() throws -> Connection {
        let helper = DatabaseHelper(config: nil)
        return try helper.getDatabase()
    }
}
