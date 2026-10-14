//
//  DatabaseProvider+WALTests.swift
//  tealium-prism_Tests
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

/// Coverage for the write-ahead-logging configuration and the checkpoint.
///
/// These exist because the pragmas are easy to break silently: a throw out of `onConfigure`
/// propagates to `DatabaseProvider`'s catch-all, which substitutes an IN-MEMORY database — the SDK
/// would keep running and lose every unsent event at app exit. Nothing in the suite noticed that before.
final class DatabaseProviderWALTests: XCTestCase {
    var path = ""
    var config = mockConfig

    override func setUp() {
        // Only the test account's folder, not the whole `tealium-prism` one, which unsandboxed apps share on macOS.
        path = (try? TealiumFileManager.getTealiumApplicationFolder().appendingPathComponent(config.account).path) ?? ""
        try? TealiumFileManager.deleteAtPath(path: path)
    }

    override func tearDown() {
        try? TealiumFileManager.deleteAtPath(path: path)
    }

    // MARK: - Journal mode

    func test_persistent_database_uses_WAL_journal_mode() throws {
        config.databaseName = "tealium"
        let database = try DatabaseProvider.openDatabase(config: config)

        let mode = try XCTUnwrap(try database.scalar("PRAGMA journal_mode") as? String)
        XCTAssertEqual(mode.lowercased(), "wal",
                       "A persistent database must use WAL. In the default rollback-journal mode "
                       + "every commit costs a flat ~45KB of disk writes regardless of payload.")
    }

    func test_persistent_database_uses_synchronous_NORMAL() throws {
        config.databaseName = "tealium"
        let database = try DatabaseProvider.openDatabase(config: config)

        // 1 == NORMAL. Under WAL this can only lose the most recent commit on OS crash or power
        // loss, never on app termination, where the log survives and is replayed on next open.
        XCTAssertEqual(try database.scalar("PRAGMA synchronous") as? Int64, 1)
    }

    func test_in_memory_database_does_not_fail_on_the_pragmas() throws {
        // `PRAGMA journal_mode = WAL` answers "memory" for an in-memory database rather than
        // throwing, so the same configuration path must be safe for both.
        let database = try DatabaseProvider.getInMemoryDatabase()
        let mode = try XCTUnwrap(try database.scalar("PRAGMA journal_mode") as? String)
        XCTAssertEqual(mode.lowercased(), "memory")
    }

    // MARK: - The queue survives, which is the point

    func test_committed_rows_survive_a_clean_close() throws {
        config.databaseName = "tealium"
        let dispatches = (0..<20).map {
            Dispatch(name: "event_\($0)", data: ["index": $0])
        }

        // Leaving the scope deallocates the provider, SQLite.swift closes the connection in its
        // `deinit`, and the close checkpoints, so this is the CLEAN close and the -wal is empty by
        // the time we reopen. The unclean case needs a connection that never closes: see
        // test_frames_left_in_the_wal_are_read_by_a_new_connection.
        do {
            let provider = try DatabaseProvider(config: config)
            let repository = SQLQueueRepository(dbProvider: provider,
                                                maxQueueSize: 100,
                                                expiration: CoreSettings().queueExpiration)
            try repository.storeDispatches(dispatches, enqueueingFor: ["Collect"])
            XCTAssertEqual(repository.size, dispatches.count)
        }

        let reopened = try DatabaseProvider(config: config)
        let repository = SQLQueueRepository(dbProvider: reopened,
                                            maxQueueSize: 100,
                                            expiration: CoreSettings().queueExpiration)
        XCTAssertEqual(repository.size, dispatches.count,
                       "Committed dispatches must survive a clean close and reopen — this is the "
                       + "delivery guarantee, and synchronous=NORMAL must not weaken it.")
    }

    func test_frames_left_in_the_wal_are_read_by_a_new_connection() throws {
        config.databaseName = "tealium"
        let dispatches = (0..<20).map {
            Dispatch(name: "event_\($0)", data: ["index": $0])
        }

        // Hold the first connection for the whole test so its `deinit`, and the checkpoint that the
        // close performs, never runs. That is the only way an in-process test can leave committed
        // frames sitting in the -wal, which is the state a killed app leaves on disk.
        let leaked = try DatabaseProvider(config: config)
        // Auto-checkpoint off too, so nothing folds the log back before the assertions.
        try leaked.database.execute("PRAGMA wal_autocheckpoint = 0")
        let repository = SQLQueueRepository(dbProvider: leaked,
                                            maxQueueSize: 100,
                                            expiration: CoreSettings().queueExpiration)
        try repository.storeDispatches(dispatches, enqueueingFor: ["Collect"])

        try withExtendedLifetime(leaked) {
            XCTAssertGreaterThan(try walSize(), 0,
                                 "The first connection must still be holding frames in the -wal, "
                                 + "otherwise the reopen below just reads the main database file "
                                 + "and proves nothing about recovery.")

            let reopened = try DatabaseProvider(config: config)
            let reopenedRepository = SQLQueueRepository(dbProvider: reopened,
                                                        maxQueueSize: 100,
                                                        expiration: CoreSettings().queueExpiration)
            XCTAssertEqual(reopenedRepository.size, dispatches.count,
                           "A new connection must read the frames left in the log. Recovery after a "
                           + "process kill runs the same mechanism, and stays a manual check.")
            XCTAssertGreaterThan(try walSize(), 0,
                                 "The rows came out of the log, not out of an already-checkpointed "
                                 + "database file: the second connection must not have folded it back.")
        }
    }

    // MARK: - Checkpoint

    func test_checkpoint_folds_the_wal_back_into_the_database_and_restarts_the_log() throws {
        config.databaseName = "tealium"
        let provider = try DatabaseProvider(config: config)

        // Auto-checkpoint off so the log is guaranteed to hold frames when we assert the
        // precondition below. Without this SQLite folds the log back on its own at the 100 pages
        // onConfigure asks for, and the test would pass even if `checkpoint()` did nothing.
        try provider.database.execute("PRAGMA wal_autocheckpoint = 0")

        let repository = SQLQueueRepository(dbProvider: provider,
                                            maxQueueSize: 500,
                                            expiration: CoreSettings().queueExpiration)
        try repository.storeDispatches((0..<100).map { Dispatch(name: "event_\($0)") },
                                       enqueueingFor: ["Collect"])

        // Precondition: there is genuinely something to fold back. This is what stops the
        // assertions below from being vacuous.
        let sizeBeforeCheckpoint = try walSize()
        XCTAssertGreaterThan(sizeBeforeCheckpoint, 0,
                             "With auto-checkpoint disabled, 100 committed dispatches must leave "
                             + "frames in the -wal; otherwise the checkpoint assertions prove nothing.")

        let result = try provider.checkpoint()

        XCTAssertFalse(result.busy, "Nothing else holds the log, so the checkpoint must complete.")
        XCTAssertGreaterThan(result.log, 0)
        XCTAssertEqual(result.checkpointed, result.log,
                       "Every committed frame must be folded back into the main database file, "
                       + "not stranded in the log between launches.")
        XCTAssertEqual(try walSize(), sizeBeforeCheckpoint,
                       "RESTART keeps the -wal at its working size for the next writer to reuse; "
                       + "journal_size_limit bounds it at that writer's reset.")

        // The data is still there: the checkpoint moved it, it did not discard it.
        XCTAssertEqual(repository.size, 100)

        // The next writer starts from the beginning of the log. A PASSIVE checkpoint reports the
        // frames the log now holds: only the new write's if the log restarted, or the earlier
        // frames plus the new ones if it did not.
        try repository.storeDispatches([Dispatch(name: "after_checkpoint")], enqueueingFor: ["Collect"])
        let afterWrite = try XCTUnwrap(try provider.database.prepare("PRAGMA wal_checkpoint(PASSIVE)")
            .failableNext()?.compactMap { $0 as? Int64 })
        XCTAssertEqual(afterWrite.count, 3)
        XCTAssertGreaterThan(afterWrite[1], 0, "The new write must be in the log.")
        XCTAssertLessThan(afterWrite[1], Int64(result.log),
                          "After the checkpoint a small write must restart the log from the "
                          + "beginning, not append to the frames already folded back.")
        XCTAssertLessThanOrEqual(try walSize(), sizeBeforeCheckpoint,
                                 "A write into a restarted log overwrites the file from the start, "
                                 + "so the -wal must not grow.")
    }

    func test_checkpoint_is_safe_on_an_in_memory_database() throws {
        // The default implementation must be a harmless no-op wherever WAL is not in use,
        // including for test doubles that never touch disk.
        let provider = try DatabaseProvider(config: mockConfig)  // no databaseName -> in memory
        XCTAssertNoThrow(try provider.checkpoint())
    }

    // MARK: - Sidecars

    func test_deleteDatabase_removes_every_sidecar() throws {
        config.databaseName = "tealium"
        let helper = DatabaseHelper(databaseUrl: try config.databaseUrl())
        _ = try helper.getDatabase()

        let databasePath = try XCTUnwrap(helper.databaseUrl?.path)
        // WAL mode never creates a rollback journal, so one is staged to prove it is removed too.
        XCTAssertTrue(FileManager.default.createFile(atPath: databasePath + "-journal", contents: Data()))
        for suffix in ["-wal", "-shm", "-journal"] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: databasePath + suffix),
                          "The \(suffix) file must exist before deleteDatabase() for this test to prove anything.")
        }
        try helper.deleteDatabase()

        for suffix in ["", "-wal", "-shm", "-journal"] {
            XCTAssertFalse(FileManager.default.fileExists(atPath: databasePath + suffix),
                           "deleteDatabase() must remove the \(suffix.isEmpty ? "database" : suffix) "
                           + "file; a stranded sidecar leaves queued event data on disk.")
        }
    }

    // MARK: - Helpers

    /// Size of the `-wal` sidecar of the database these tests open, 0 only when its folder cannot be
    /// resolved. Throws when the file cannot be read, so a missing `-wal` fails the test instead of
    /// passing as an empty log.
    private func walSize() throws -> Int {
        let url = try TealiumFileManager.getApplicationFileUrl(for: config.account,
                                                               profile: config.profile,
                                                               fileName: "tealium.sqlite3")
        return try FileManager.default.attributesOfItem(atPath: url.path.appending("-wal"))[.size] as? Int ?? 0
    }
}
