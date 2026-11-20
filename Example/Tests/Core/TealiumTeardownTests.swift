//
//  TealiumTeardownTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 03/11/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

/**
 * Checks that a `TealiumImpl` releases everything it built, and closes its database connection, both when
 * `TealiumInstanceManager.create` fails and after `shutdown()`.
 *
 * Swift has no explicit close: SQLite.swift's `Connection.deinit` closes the connection once its only owner,
 * `DatabaseConnection`, is released. Releases are checked with weak references, and the close with the
 * process's open file descriptors and with the -wal file, which the last connection to close checkpoints and empties.
 */
final class TealiumTeardownTests: XCTestCase {

    /// The account shared by every test, each with the name of the test as its profile. Its folder is removed before and after each test.
    private static let account = "teardownAccount"

    private let manager = TealiumInstanceManager(queue: .worker)

    override func setUpWithError() throws {
        try super.setUpWithError()
        try removeAccountFolderNowAndAtTeardown(account: Self.account)
    }

    // MARK: - Failed create

    /// The corruption is found at a start-up read after the store provider, the settings manager, the queue and the
    /// dispatch manager are built, so `init` throws late, at the data layer's store.
    func test_failed_create_on_a_corrupt_database_closes_the_database_releases_the_logger_and_stores_no_instance() throws {
        var config = fileDatabaseConfig(account: Self.account, profile: #function)
        try stageQueuedDispatchesWithDamagedTail(config: config)
        let client = LoggerRecordingNetworkClient()
        config.networkClient = client

        let error = try createExpectingFailure(config: config, in: manager)
        TealiumQueue.worker.dispatchQueue.sync { }

        XCTAssertConnectionClosed(error)
        assertNoInstanceStored(for: config)
        assertTornDown(client: client, config: config)
    }

    /// `init` throws early, at the settings manager, with the database file open and written to.
    func test_failed_create_on_an_invalid_settings_url_closes_the_database_connection() throws {
        var config = fileDatabaseConfig(account: Self.account, profile: #function, settingsUrl: "")
        let databasePath = try XCTUnwrap(config.databaseUrl()).path
        let client = LoggerRecordingNetworkClient()
        config.networkClient = client

        let error = try createExpectingFailure(config: config, in: manager)

        guard case .invalidUrl? = error as? ConversionError else {
            return XCTFail("\(error) is not ConversionError.invalidUrl")
        }
        assertNoInstanceStored(for: config)
        assertTornDown(client: client, config: config, walAt: databasePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: databasePath))
    }

    // MARK: - Initialization failure log

    func test_an_early_initialization_failure_is_logged_once() throws {
        let config = fileDatabaseConfig(account: Self.account, profile: #function, settingsUrl: "", minLogLevel: .error)
        let errors = try errorsLoggedByFailedCreate(config: config)
        XCTAssertEqual(errors.filter { $0.hasPrefix("Tealium initialization failed") }.count, 1, "\(errors)")
    }

    func test_a_late_initialization_failure_is_logged_once() throws {
        let config = fileDatabaseConfig(account: Self.account, profile: #function, minLogLevel: .error)
        try stageDataLayerRegistrationFailure(config)
        let errors = try errorsLoggedByFailedCreate(config: config)
        XCTAssertEqual(errors.filter { $0.hasPrefix("Tealium initialization failed") }.count, 1, "\(errors)")
        XCTAssertTrue(errors.contains { $0.contains("data layer registration refused") }, "\(errors)")
    }

    /// `init` throws late, at the data layer's store, with the database connection open, not closed by a corruption.
    func test_failed_create_at_the_data_layer_store_closes_the_database_connection() throws {
        var config = fileDatabaseConfig(account: Self.account, profile: #function)
        let databasePath = try XCTUnwrap(config.databaseUrl()).path
        try stageDataLayerRegistrationFailure(config)
        let client = LoggerRecordingNetworkClient()
        config.networkClient = client

        let error = try createExpectingFailure(config: config, in: manager)

        XCTAssertNil(DatabaseHelper.corruptionCode(error), "\(error)")
        XCTAssertTrue("\(error)".contains("data layer registration refused"), "\(error)")
        assertNoInstanceStored(for: config)
        assertTornDown(client: client, config: config, walAt: databasePath)
    }

    /// As above, with the start-up settings refresh still in flight when `init` throws: the request's completion, held by the
    /// network client as `URLSession` would hold it, must not keep anything alive.
    func test_failed_create_with_a_settings_request_in_flight_closes_the_database_connection() throws {
        var config = fileDatabaseConfig(account: Self.account, profile: #function, settingsUrl: Self.settingsUrl)
        let databasePath = try XCTUnwrap(config.databaseUrl()).path
        try stageDataLayerRegistrationFailure(config)
        let client = LoggerRecordingNetworkClient()
        let pending = PendingRequests(holding: client)
        config.networkClient = client

        let error = try createExpectingFailure(config: config, in: manager)

        XCTAssertTrue("\(error)".contains("data layer registration refused"), "\(error)")
        withExtendedLifetime(pending) {
            XCTAssertEqual(pending.count, 1, "The settings request is not in flight")
            assertTornDown(client: client, config: config, walAt: databasePath)
        }
    }

    // MARK: - Shutdown

    func test_shutdown_releases_everything_and_closes_the_database_connection() throws {
        var config = fileDatabaseConfig(account: Self.account, profile: #function, minLogLevel: .debug)
        let databasePath = try XCTUnwrap(config.databaseUrl()).path
        let client = LoggerRecordingNetworkClient()
        config.networkClient = client
        let logHandler = MockLogHandler()
        config.loggerType = .custom(logHandler)
        let checkpointLogged = expectation(description: "The shutdown checkpoint is logged")
        let subscription = logHandler.onLogged
            .filter { $0.category == LogCategory.persistence && $0.message.hasPrefix("WAL checkpoint at shutdown:") }
            .subscribeOnce { _ in checkpointLogged.fulfill() }

        let tealium = try createExpectingSuccess(config: config, in: manager)
        try trackAndWaitForDispatch(tealium, event: "before_shutdown")
        let probes = try internalProbes(of: config) + [ReleaseProbe("TealiumLogger", client.logger)]
        // Controls: while the connection is open, its files are open and the -wal holds frames.
        XCTAssertFalse(openDatabaseFiles(of: config).isEmpty, "The probe for open files sees none before shutdown")
        XCTAssertGreaterThan(try walSize(ofDatabaseAt: databasePath), 0)

        shutDownAndWait(tealium, in: manager)
        wait(for: [checkpointLogged], timeout: Self.longTimeout)
        subscription.dispose()

        // `tealium` is still held, as an app holds its instance after calling `shutdown()`.
        withExtendedLifetime(tealium) {
            assertReleased(probes)
            XCTAssertEqual(openDatabaseFiles(of: config), [])
            assertWALEmptied(ofDatabaseAt: databasePath)
        }

        // Nothing holds the file any longer: it can be deleted, and a new instance recreates it and dispatches.
        try FileManager.default.removeItem(atPath: databasePath)
        let secondManager = TealiumInstanceManager(queue: .worker)
        config.loggerType = .custom(MockLogHandler())
        config.networkClient = MockNetworkClient(result: .success(.successful()))
        let second = try createExpectingSuccess(config: config, in: secondManager)
        try trackAndWaitForDispatch(second, event: "after_reopen")
        XCTAssertTrue(FileManager.default.fileExists(atPath: databasePath))
        shutDownAndWait(second, in: secondManager)
        XCTAssertEqual(try integrityCheck(ofDatabaseAt: databasePath), "ok")
    }

    func test_shutdown_with_a_settings_request_in_flight_releases_everything() throws {
        var config = fileDatabaseConfig(account: Self.account, profile: #function, settingsUrl: Self.settingsUrl)
        let databasePath = try XCTUnwrap(config.databaseUrl()).path
        let client = LoggerRecordingNetworkClient()
        let pending = PendingRequests(holding: client)
        config.networkClient = client

        let tealium = try createExpectingSuccess(config: config, in: manager)
        let probes = try internalProbes(of: config) + [ReleaseProbe("TealiumLogger", client.logger)]
        XCTAssertFalse(openDatabaseFiles(of: config).isEmpty, "The probe for open files sees none before shutdown")

        shutDownAndWait(tealium, in: manager)

        withExtendedLifetime((tealium, pending)) {
            XCTAssertEqual(pending.count, 1, "The settings request is not in flight")
            assertReleased(probes)
            XCTAssertEqual(openDatabaseFiles(of: config), [])
            assertWALEmptied(ofDatabaseAt: databasePath)
        }
    }

    // MARK: - Helpers

    private static let settingsUrl = "https://tags.tiqcdn.com/dle/mockAccount/mockProfile/mockEnv/settings.json"

    /// The `error` messages logged while `create` fails with `config`.
    private func errorsLoggedByFailedCreate(config: TealiumConfig) throws -> [String] {
        var config = config
        let logHandler = MockLogHandler()
        config.loggerType = .custom(logHandler)
        return try logHandler.messagesLogged(at: .error, whileExecuting: {
            _ = try createExpectingFailure(config: config, in: manager)
            TealiumQueue.worker.dispatchQueue.sync { }
        })
    }

    /// Makes the database file of `config` refuse to register the data layer's module, so that `init` throws at the data layer's store.
    private func stageDataLayerRegistrationFailure(_ config: TealiumConfig) throws {
        let connection = try DatabaseProvider.openDatabase(config: config).connection
        try connection.execute("""
            CREATE TRIGGER fail_data_layer BEFORE INSERT ON module WHEN NEW.name = '\(Modules.Types.dataLayer)'
            BEGIN SELECT RAISE(ABORT, 'data layer registration refused'); END;
            """)
    }

    /// Asserts that the failed create stored no instance in the manager.
    private func assertNoInstanceStored(for config: TealiumConfig) {
        TealiumQueue.worker.dispatchQueue.sync {
            XCTAssertNil(manager.instances[config.key])
        }
    }

    /// Asserts that the failed create released the logger it handed to `client` and left no database file open, and, given
    /// the path of the database, that its -wal file is empty.
    private func assertTornDown(client: LoggerRecordingNetworkClient, config: TealiumConfig, walAt databasePath: String? = nil,
                                file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(client.receivedLogger, file: file, line: line)
        assertReleased([ReleaseProbe("TealiumLogger", client.logger)], file: file, line: line)
        XCTAssertEqual(openDatabaseFiles(of: config), [], file: file, line: line)
        if let databasePath {
            assertWALEmptied(ofDatabaseAt: databasePath, file: file, line: line)
        }
    }

    /// Weak references to the objects the stored `TealiumImpl` owns, taken on the worker queue.
    private func internalProbes(of config: TealiumConfig) throws -> [ReleaseProbe] {
        try TealiumQueue.worker.dispatchQueue.sync {
            let impl = try XCTUnwrap(manager.instances[config.key]?.instance)
            let databaseProvider = impl.context.moduleStoreProvider.databaseProvider
            let database = databaseProvider.database
            return [
                ReleaseProbe("TealiumImpl", impl),
                ReleaseProbe("TealiumContext", impl.context),
                ReleaseProbe("SettingsManager", impl.settingsManager),
                ReleaseProbe("ModuleManager", impl.moduleManager),
                ReleaseProbe("MockDispatcher", impl.moduleManager.getModule(MockDispatcher.self)),
                ReleaseProbe("SessionManager", impl.sessionManager),
                ReleaseProbe("QueueManager", impl.queueManager),
                ReleaseProbe("TrackerImpl", impl.tracker),
                ReleaseProbe("DispatchManager", impl.tracker.dispatchManager as AnyObject),
                ReleaseProbe("BarrierCoordinator", impl.barrierCoordinator),
                ReleaseProbe("LoadRuleEngine", impl.loadRuleEngine),
                ReleaseProbe("ModuleStoreProvider", impl.context.moduleStoreProvider),
                ReleaseProbe("DatabaseProvider", databaseProvider as AnyObject),
                ReleaseProbe("DatabaseConnection", database),
            ]
        }
    }

    /// Asserts that every probe is released once the work already queued on the worker queue has run.
    private func assertReleased(_ probes: [ReleaseProbe], file: StaticString = #filePath, line: UInt = #line) {
        TealiumQueue.worker.dispatchQueue.sync { }
        XCTAssertEqual(probes.filter { $0.object != nil }.map { $0.name }, [], file: file, line: line)
    }

    /// The paths of this process's file descriptors that point into the database files of `config`.
    ///
    /// Skips event-only descriptors: excluding a file from backup makes CoreServices open it `O_EVTONLY` for a few
    /// microseconds on its own queue, which a scan could otherwise catch. SQLite never opens its files that way.
    private func openDatabaseFiles(of config: TealiumConfig) -> [String] {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        return (0..<getdtablesize()).compactMap { descriptor -> String? in
            guard fcntl(descriptor, F_GETPATH, &buffer) != -1 else { return nil }
            let path = String(cString: buffer)
            guard path.contains("/\(config.account)/\(config.profile)/") && path.contains("tealium.sqlite3") else { return nil }
            // Checked after the path: a descriptor closed in between returns -1 and is skipped.
            let flags = fcntl(descriptor, F_GETFL)
            return flags != -1 && flags & O_EVTONLY == 0 ? path : nil
        }
    }

    /**
     * Asserts that the -wal file is gone or empty, as the last connection to close leaves it.
     *
     * Apple's SQLite enables `SQLITE_FCNTL_PERSIST_WAL` by default, so the close keeps the -wal and -shm files instead of
     * deleting them, and truncates the -wal to zero bytes. The `RESTART` checkpoint at shutdown doesn't truncate it.
     */
    private func assertWALEmptied(ofDatabaseAt path: String, file: StaticString = #filePath, line: UInt = #line) {
        // A missing -wal throws, and counts as emptied.
        XCTAssertEqual((try? walSize(ofDatabaseAt: path)) ?? 0, 0, "\(path)-wal is not empty", file: file, line: line)
    }
}

/// A weak reference to an object that is expected to be released, and the name to report it by.
private struct ReleaseProbe {
    let name: String
    #if compiler(>=6.2.3)
    weak let object: AnyObject?
    #else
    weak var object: AnyObject?
    #endif

    init(_ name: String, _ object: AnyObject?) {
        self.name = name
        self.object = object
    }
}

/// Records, weakly, the logger that `TealiumImpl.init` builds and hands to the network client, before anything that
/// can throw. `DatabaseConnection` holds that logger through its `onCorruption` closure, so the logger outliving a
/// failed create would mean that the connection wrapper, or another holder of the logger, leaked.
private final class LoggerRecordingNetworkClient: MockNetworkClient {
    weak var logger: AnyObject?
    /// Whether `logger` was ever set, so that a `nil` one means released, not never received.
    private(set) var receivedLogger = false

    init() {
        super.init(result: .success(.successful()))
    }

    override func newClient(withLogger logger: any LoggerProtocol) -> Self {
        self.logger = logger as AnyObject
        receivedLogger = true
        return self
    }
}

/// Holds every request sent through `client` without ever completing it, as `URLSession` holds an in-flight request's completion.
private final class PendingRequests {
    private var blocks = [() -> Void]()
    var count: Int { blocks.count }

    init(holding client: MockNetworkClient) {
        client.delayBlock = { [unowned self] block in
            blocks.append(block)
        }
    }
}
