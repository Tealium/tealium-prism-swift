//
//  TealiumTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class TealiumBaseTests: XCTestCase {
    let client = MockNetworkClient(result: .success(.successful()))
    var queue: TealiumQueue {
        instanceManager.queue
    }
    let instanceManager = TealiumInstanceManager(queue: .worker)
    var minLogLevel = LogLevel.Minimum.silent
    var settingsFile: String?
    var settingsUrl: String?
    lazy var config = createConfig()

    func createConfig() -> TealiumConfig {
        var config = TealiumConfig(account: "mockAccount",
                                   profile: "mockProfile",
                                   environment: "mockEnv",
                                   modules: [],
                                   settingsFile: settingsFile,
                                   settingsUrl: settingsUrl) { builder in
            builder.setMinLogLevel(self.minLogLevel)
        }
        config.databaseName = nil
        config.networkClient = client
        return config
    }

    lazy private(set) var disposer = AsyncDisposableContainer(queue: queue)

    func createTealium(completion: ((InitializationResult<Tealium>) -> Void)? = nil) -> Tealium {
        instanceManager.create(config: config, completion: completion)
    }

    override class func setUp() {
        super.setUp()
        TealiumQueue.worker.enforceQoS = .userInitiated
    }

    override class func tearDown() {
        super.tearDown()
        TealiumQueue.worker.enforceQoS = .unspecified
    }

    override func tearDown() {
        super.tearDown()
        waitForDispatchQueueToBeEmpty {
            // Dropping the manager's strong references lets any remaining instances deallocate.
            self.instanceManager.instances.removeAll()
            self.disposer.dispose()
        }
    }

    /// Waits for the blocks currently dispatched to the queue to be completed synchronously.
    func waitForDispatchQueueToBeEmpty(work: @escaping () -> Void = { }) {
        self.queue.dispatchQueue.sync(execute: work)
    }
}

final class TealiumTests: TealiumBaseTests {
    func test_create_completes_on_our_queue() {
        let initCompleted = expectation(description: "Tealium init completed")
        _ = createTealium { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            initCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_onReady_completes_on_our_queue() {
        let onReadyCompleted = expectation(description: "Tealium onReady completed")
        let teal = createTealium()
        teal.onReady { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            onReadyCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_track_arrives_to_dispatcher() {
        let dispatched = expectation(description: "The Dispatch is dispatched to the dispatcher")
        config.addModule(MockDispatcher.factory())
        let teal = createTealium()
        MockDispatcher.onDispatch.subscribeOnce { dispatches in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            dispatched.fulfill()
            XCTAssertEqual(dispatches.map { $0.name }, ["Event"])
        }
        teal.track("Event")
        waitForLongTimeout()
    }

    func test_track_mapped_dispatch_arrives_to_dispatcher() {
        let dispatched = expectation(description: "The Dispatch is dispatched to the dispatcher")
        let moduleSettings = DispatcherSettingsBuilder()
            .setMappings({ mappings in
                mappings.mapFrom("tealium_event", to: "mapped_event")
            })
        config.addModule(MockDispatcher.factory(enforcedSettings: moduleSettings))
        let teal = createTealium()
        MockDispatcher.onDispatch.subscribeOnce { dispatches in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            dispatched.fulfill()
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.payload, ["mapped_event": "Event"])
        }
        teal.track("Event")
        waitForLongTimeout()
    }

    func test_no_retain_cycle_after_track_and_shutdown() {
        let trackCompleted = expectation(description: "The track was completed")
        config.addModule(MockDispatcher.factory())
        let helper = RetainCycleHelper(variable: createTealium())
        helper.strongVariable?.track("Event").subscribe { result in
            XCTAssertResultIsSuccess(result)
            trackCompleted.fulfill()
        }
        waitOnQueue(queue: instanceManager.queue, timeout: Self.defaultTimeout)
        // With strong references, teardown is driven by an explicit shutdown, not by ARC.
        instanceManager.shutdown(config.key)
        waitForDispatchQueueToBeEmpty()
        helper.forceAndAssertObjectDeinit()
    }

    func test_flush_completes_on_our_queue() {
        let flushCompleted = expectation(description: "Tealium flush completed")
        let teal = createTealium()
        _ = teal.flushEventQueue().subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            flushCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_module_shutdown_on_our_queue_when_tealium_shutdown() {
        let initCompleted = expectation(description: "Tealium init completed")
        config.addModule(MockDispatcher.factory())
        let teal = createTealium { _ in
            initCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
        let moduleShutdown = expectation(description: "Module is shutdown")
        MockDispatcher.onShutdown.subscribeOnce {
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            moduleShutdown.fulfill()
        }
        teal.shutdown()
        waitOnQueue(queue: queue)
    }

    func test_resetVisitorId_completes_on_our_queue() {
        let resetCompleted = expectation(description: "Reset visitorId completed")
        let teal = createTealium()
        teal.resetVisitorId().subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            resetCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_clearStoredVisitorIds_completes_on_our_queue() {
        let clearCompleted = expectation(description: "Clear completed")
        let teal = createTealium()
        teal.clearStoredVisitorIds().subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            clearCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_dataLayer_wrapper_works_on_our_queue() {
        let putCompleted = expectation(description: "Put completed")
        let dataUpdated = expectation(description: "Data updated")
        let teal = createTealium()
        _ = teal.dataLayer.onDataUpdated.subscribe { newData in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            dataUpdated.fulfill()
            XCTAssertEqual(newData, ["some_key": "some_value"])
        }
        teal.dataLayer.put(key: "some_key", value: "some_value").subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            putCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_deepLink_wrapper_works_on_our_queue() throws {
        let handleDeeplinkCompleted = expectation(description: "Handle deeplink completed")
        config.addModule(Modules.deepLink())
        let teal = createTealium()
        teal.deepLink.handle(link: try "https://www.tealium.com".asUrl(), referrer: nil).subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_deepLink_wrapper_with_traceId_succeeds_if_trace_enabled() throws {
        let handleDeeplinkCompleted = expectation(description: "Handle deeplink completed")
        config.addModule(Modules.deepLink())
        config.addModule(Modules.trace())
        let teal = createTealium()
        teal.deepLink.handle(link: try "https://www.tealium.com?tealium_trace_id=123".asUrl(), referrer: nil).subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_deepLink_wrapper_with_traceId_fails_if_trace_disabled() throws {
        let handleDeeplinkCompleted = expectation(description: "Handle deeplink completed")
        config.addModule(Modules.deepLink())
        let teal = createTealium()
        teal.deepLink.handle(link: try "https://www.tealium.com?tealium_trace_id=123".asUrl(), referrer: nil).subscribe { result in
            XCTAssertResultIsFailure(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_deeplink_wrapper_throws_errors_if_not_enabled() throws {
        let handleDeeplinkCompleted = expectation(description: "Handle deeplink completed")
        config.addModule(Modules.deepLink(forcingSettings: { enforcedSettings in
            enforcedSettings.setEnabled(false)
        }))
        let teal = createTealium()
        teal.deepLink.handle(link: try "https://www.tealium.com".asUrl(), referrer: nil).subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let object) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == "\(DeepLinkModule.self)")
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_deeplink_wrapper_throws_errors_if_not_added() throws {
        let handleDeeplinkCompleted = expectation(description: "Handle deeplink completed")
        let teal = createTealium()
        teal.deepLink.handle(link: try "https://www.tealium.com".asUrl(), referrer: nil).subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let object) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == "\(DeepLinkModule.self)")
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_trace_wrapper_works_on_our_queue() throws {
        let joinTraceCompleted = expectation(description: "Join trace completed")
        config.addModule(Modules.trace())
        let teal = createTealium()
        teal.trace.join(id: "new trace").subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            joinTraceCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_trace_wrapper_throws_errors_if_not_enabled() throws {
        let joinTraceCompleted = expectation(description: "Join trace completed")
        config.addModule(Modules.trace(forcingSettings: { enforcedSettings in
            enforcedSettings.setEnabled(false)
        }))
        let teal = createTealium()
        teal.trace.join(id: "new trace").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let object) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == "\(TraceModule.self)")
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            joinTraceCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_trace_wrapper_throws_errors_if_not_added() throws {
        let joinTraceCompleted = expectation(description: "Join trace completed")
        let teal = createTealium()
        teal.trace.join(id: "new trace").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let object) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == "\(TraceModule.self)")
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            joinTraceCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_multiple_instances_share_same_implementation() {
        let tealiumImplementationsCreated = expectation(description: "Both tealium implementations are created")
        let teal1 = createTealium()
        let teal2 = createTealium()
        XCTAssertNotIdentical(teal1, teal2)
        teal1.proxy.getProxiedObject { impl1 in
            teal2.proxy.getProxiedObject { impl2 in
                tealiumImplementationsCreated.fulfill()
                XCTAssertIdentical(impl1, impl2)
            }
        }
        waitOnQueue(queue: queue)
    }

#if os(iOS) || os(tvOS)
    func test_backgrounding_the_app_starts_background_task_if_queue_not_empty() {
        let notificationCenter = NotificationCenter()
        config.appStatusListener = ApplicationStatusListener(notificationCenter: notificationCenter)
        config.addModule(Modules.collect())
        config.addBarrier(Barriers.batching())
        let starter = MockBackgroundTaskStarter(queue: queue, backgroundTaskTimeout: .seconds(5))
        config.backgroundTaskStarter = starter
        let tealiumInitialized = expectation(description: "Tealium is initialized")
        let backgroundTaskStarted = expectation(description: "Background task is started")
        let teal = createTealium()
        let disposable = AsyncDisposableContainer(queue: queue)
        var count = 0
        teal.track("Some Event")
        _ = teal.proxy.executeTask { _ in
            starter.onBackgroundTaskStarted.subscribe { ongoing in
                if count == 0 {
                    XCTAssertFalse(ongoing)
                } else {
                    XCTAssertTrue(ongoing)
                    backgroundTaskStarted.fulfill()
                }
                count += 1
            }.addTo(disposable)
            tealiumInitialized.fulfill()
            DispatchQueue.main.async {
                notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
            }
        }
        waitForLongTimeout()
        disposable.dispose()
    }
#endif

    func test_second_factory_added_with_same_moduleType_is_discarded() {
        config.addModule(MockDispatcher1.factory(allowsMultipleInstances: true,
                                                 enforcedSettings: MultipleInstancesSettingsBuilder()
            .setModuleId("Module1")
            .setOrder(1)))
        config.addModule(MockDispatcher1.factory(allowsMultipleInstances: true,
                                                 enforcedSettings: MultipleInstancesSettingsBuilder()
            .setModuleId("Module2")
            .setOrder(2)))
        let initializationCompleted = expectation(description: "Tealium initialization completed")
        let teal = createTealium()
        _ = teal.proxy.executeTask { impl in
            let modules = impl.modulesManager.modules.value.map { $0.id }
            XCTAssertTrue(modules.contains("Module1"))
            XCTAssertFalse(modules.contains("Module2"))
            initializationCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_dispatcher_holding_context_deinitializes_after_shutdown() {
        let dispatcherDeinitialized = expectation(description: "Dispatcher containing TealiumContext is deinitialized")
        DispatcherWithContext.onCreate
            .first()
            .flatMap(\.onDeinit)
            .subscribe {
                dispatcherDeinitialized.fulfill()
            }
        config.addModule(BasicModuleFactory<DispatcherWithContext>(moduleType: "DispatcherWithContext",
                                                                   enforcedSettings: [:]))
        let initializationCompleted = expectation(description: "Tealium initialization completed")
        var teal: Tealium? = createTealium { _ in
            initializationCompleted.fulfill()
        }
        wait(for: [initializationCompleted], timeout: Self.longTimeout)
        #if compiler(>=6.2.3)
        weak let weakTeal = teal
        #else
        weak var weakTeal = teal
        #endif
        // The manager retains the instance strongly, so shutdown is required to release it.
        teal?.shutdown()
        waitForDispatchQueueToBeEmpty()
        teal = nil
        XCTAssertNil(weakTeal)
        waitForLongTimeout()
    }
}

/// A Dispatcher holding a strong reference of the `TealiumContext` to simulate a potential retain cycle
private class DispatcherWithContext: Dispatcher, BasicModule {
    let context: TealiumContext
    @Subject<DispatcherWithContext> static var onCreate
    @Subject<Void> var onDeinit
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.context = context
        Self._onCreate.onNext(self)
    }

    func dispatch(_ data: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> any Disposable {
        completion(data)
        return Disposables.disposed()
    }

    let version: String = TealiumConstants.libraryVersion

    let id: String = "DispatcherWithContext"

    deinit {
        _onDeinit.onNext()
    }

}
