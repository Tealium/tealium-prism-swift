//
//  Connection+WALCheckpoint.swift
//  tealium-prism
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite

extension Connection {
    /// Checkpoints the write-ahead log in `RESTART` mode, not `TRUNCATE`: the next writer reuses the `-wal` instead of regrowing it.
    ///
    /// SQLite.swift 0.17's `walCheckpoint(mode:schema:)` would replace this, but Prism pins `~> 0.15.4`: 0.17 needs iOS 15, macOS 12,
    /// watchOS 9 and Swift tools 6.1.
    func walCheckpointRestart() throws -> (busy: Bool, log: Int, checkpointed: Int) {
        let statement = try prepare("PRAGMA wal_checkpoint(RESTART)")
        _ = try statement.step()
        let busy: Int64 = statement.row[0]
        let log: Int64 = statement.row[1]
        let checkpointed: Int64 = statement.row[2]
        return (busy != 0, Int(log), Int(checkpointed))
    }
}
