//
//  TealiumImplementationTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 09/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TealiumImplementationTests: XCTestCase {

    /// Stands in for `ModuleManager.observeModules`, which is what feeds the processors in production.
    @ReplaySubject<[Dispatcher]> var onDispatchers

    private func makeImplementation(modules: [any ModuleFactory] = []) throws -> TealiumImpl {
        var config = TealiumConfig(account: "mockAccount",
                                   profile: "mockProfile",
                                   environment: "mockEnv",
                                   modules: modules,
                                   settingsFile: nil,
                                   settingsUrl: nil) { builder in
            builder.setMinLogLevel(.silent)
        }
        config.databaseName = nil
        config.networkClient = MockNetworkClient(result: .success(.successful()))
        return try TealiumImpl(config, queue: .worker)
    }

    func test_init_logs_an_error_when_initialization_fails() throws {
        let logHandler = MockLogHandler()
        var config = TealiumConfig(account: "mockAccount",
                                   profile: "mockProfile",
                                   environment: "mockEnv",
                                   modules: [],
                                   settingsFile: nil,
                                   settingsUrl: "")
        config.loggerType = .custom(logHandler)
        config.databaseName = "tealium"
        config.networkClient = MockNetworkClient(result: .success(.successful()))
        // The database file location cannot be created.
        try blockAccountFolder(config.account)
        let errorLogged = expectation(description: "Initialization failure is logged")
        let locationLogged = expectation(description: "File location failure is logged")
        let subscription = logHandler.onLogged.subscribe { event in
            guard event.level == .error else { return }
            if event.category == LogCategory.tealium && event.message.contains("Tealium initialization failed") {
                errorLogged.fulfill()
            }
            if event.category == LogCategory.persistence
                && event.message.contains("the database file location could not be created") {
                locationLogged.fulfill()
            }
        }
        // On the worker queue, as TealiumInstanceManager does: the logger is released when init throws.
        XCTAssertThrowsError(try TealiumQueue.worker.dispatchQueue.sync { try TealiumImpl(config, queue: .worker) }) { error in
            guard case .invalidUrl(let url)? = error as? ConversionError, "\(url)" == "" else {
                return XCTFail("Expected ConversionError.invalidUrl for the empty settings URL but got \(error)")
            }
        }
        waitForDefaultTimeout()
        subscription.dispose()
    }

    func test_isShutdown_is_false_before_shutdown() throws {
        let instance = try makeImplementation()
        XCTAssertFalse(instance.isShutdown)
    }

    func test_isShutdown_is_true_after_shutdown() throws {
        let instance = try makeImplementation()
        instance.shutdown()
        XCTAssertTrue(instance.isShutdown)
    }

    func test_shutdown_can_be_called_multiple_times() throws {
        let instance = try makeImplementation()
        instance.shutdown()
        instance.shutdown()
        XCTAssertTrue(instance.isShutdown)
    }

    /**
     * Every emission makes the queue delete the queues of the processors that are not in the list, so
     * nothing may be emitted until the modules are ready. That gate lives in `ModuleManager` now,
     * and this only has to not emit an answer of its own before the dispatchers arrive.
     */
    func test_queueProcessors_doesnt_emit_until_the_dispatchers_do() {
        let queueProcessorsDoesntEmit = expectation(description: "QueueProcessors doesn't emit before the dispatchers")
        queueProcessorsDoesntEmit.isInverted = true
        TealiumImpl.queueProcessors(from: onDispatchers, addingConsent: false)
            .subscribeOnce { _ in
                queueProcessorsDoesntEmit.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_queueProcessors_emits_all_dispatchers() {
        let dispatchers = [MockDispatcher1(), MockDispatcher2()]
        _onDispatchers.onNext(dispatchers)
        let queueProcessorsEmits = expectation(description: "QueueProcessors emits processors")
        TealiumImpl.queueProcessors(from: onDispatchers, addingConsent: false)
            .subscribeOnce { processors in
                XCTAssertEqual(processors, dispatchers.map { $0.id })
                queueProcessorsEmits.fulfill()
            }
        waitForDefaultTimeout()
    }

    /// No dispatcher enabled is an answer, unlike no emission at all: those queues have no owner left.
    func test_queueProcessors_emits_only_the_consent_manager_when_no_dispatcher_is_enabled() {
        _onDispatchers.onNext([])
        let queueProcessorsEmits = expectation(description: "QueueProcessors emits processors")
        TealiumImpl.queueProcessors(from: onDispatchers, addingConsent: true)
            .subscribeOnce { processors in
                XCTAssertEqual(processors, ["consent"])
                queueProcessorsEmits.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_queueProcessors_emits_consent_manager() {
        let dispatchers = [MockDispatcher1(), MockDispatcher2()]
        _onDispatchers.onNext(dispatchers)
        let queueProcessorsEmits = expectation(description: "QueueProcessors emits processors")
        TealiumImpl.queueProcessors(from: onDispatchers, addingConsent: true)
            .subscribeOnce { processors in
                XCTAssertEqual(processors, dispatchers.map { $0.id } + ["consent"])
                queueProcessorsEmits.fulfill()
            }
        waitForDefaultTimeout()
    }
    /**
     * A shutdown is not a configuration change: clearing the modules must not reach the queue, or the
     * dispatches still waiting for their dispatcher would be deleted instead of being sent next launch.
     */
    func test_shutdown_does_not_delete_the_dispatches_left_in_the_queue() throws {
        let instance = try makeImplementation(modules: [MockDispatcher.factory()])
        let processor = try XCTUnwrap(instance.moduleManager.modules.value
            .compactMap { $0 as? Dispatcher }
            .first?.id)
        // Nothing may dequeue the dispatch before the shutdown.
        instance.tracker.dispatchManager.stopDispatchLoop()
        instance.queueManager.storeDispatches([Dispatch(name: "event")], enqueueingFor: [processor])
        instance.shutdown()
        XCTAssertEqual(instance.queueManager.peekDispatches(for: processor, limit: nil).count, 1)
    }

    func test_backgrounded_checkpoints_the_database() throws {
        let checkpointed = expectation(description: "The background checkpoint is logged")
        try backgroundImplementation(databaseName: "tealium") { message in
            if message.hasPrefix("WAL checkpoint at backgrounding:") {
                checkpointed.fulfill()
            }
        }
    }

    func test_backgrounded_does_not_log_a_checkpoint_for_an_in_memory_database() throws {
        let checkpointLogged = expectation(description: "No checkpoint is logged without WAL")
        checkpointLogged.isInverted = true
        try backgroundImplementation(databaseName: nil) { message in
            if message.hasPrefix("WAL checkpoint at backgrounding") {
                checkpointLogged.fulfill()
            }
        }
    }

    /// Starts an implementation with debug logs, sends the app to the background, and hands every
    /// persistence log message to `onPersistenceLog` until the expectations are met.
    private func backgroundImplementation(databaseName: String?, onPersistenceLog: @escaping (String) -> Void) throws {
        let logHandler = MockLogHandler()
        let notificationCenter = NotificationCenter()
        var config = TealiumConfig(account: "walCheckpointAccount",
                                   profile: "mockProfile",
                                   environment: "mockEnv",
                                   modules: [],
                                   settingsFile: nil,
                                   settingsUrl: nil) { builder in
            builder.setMinLogLevel(.debug)
        }
        config.loggerType = .custom(logHandler)
        config.databaseName = databaseName
        config.networkClient = MockNetworkClient(result: .success(.successful()))
        config.appStatusListener = ApplicationStatusListener(notificationCenter: notificationCenter)
        let accountPath = try TealiumFileManager.getTealiumApplicationFolder().appendingPathComponent(config.account).path
        try? TealiumFileManager.deleteAtPath(path: accountPath)
        addTeardownBlock { try? TealiumFileManager.deleteAtPath(path: accountPath) }
        let subscription = logHandler.onLogged.subscribe { event in
            guard event.category == LogCategory.persistence else { return }
            onPersistenceLog(event.message)
        }
        let instance = try TealiumQueue.worker.dispatchQueue.sync { try TealiumImpl(config, queue: .worker) }
        notificationCenter.postResignActiveNotification()
        waitForDefaultTimeout()
        subscription.dispose()
        TealiumQueue.worker.dispatchQueue.sync { instance.shutdown() }
    }
}
