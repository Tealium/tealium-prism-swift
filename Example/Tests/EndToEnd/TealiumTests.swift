//
//  TealiumTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 15/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class TealiumBaseTests: XCTestCase {
    let client = MockNetworkClient(result: .success(.successful()))
    var queue: TealiumQueue {
        instanceManager.queue
    }
    let instanceManager = TealiumInstanceManager(queue: .worker)
    lazy var config = TealiumConfig(account: "mockAccount",
                                    profile: "mockProfile",
                                    environment: "mockEnv",
                                    modules: [],
                                    settingsFile: nil,
                                    settingsUrl: nil) { builder in
        builder.setMinLogLevel(.silent)
    }

    let disposer = DisposeContainer()

    func createTealium(completion: ((Tealium.InitializationResult) -> Void)? = nil) -> Tealium {
        instanceManager.create(config: config, completion: completion)
    }

    override func setUp() {
        super.setUp()
        queue.dispatchQueue.sync {
            try? TealiumFileManager.deleteAtPath(path: TealiumFileManager.getTealiumApplicationFolder().path)
        }
    }

    override func tearDown() {
        super.tearDown()
        queue.dispatchQueue.sync {
            instanceManager.proxies.removeAll()
            instanceManager.instances.removeAll()
            try? TealiumFileManager.deleteAtPath(path: TealiumFileManager.getTealiumApplicationFolder().path)
            disposer.dispose()
        }
    }
}

final class TealiumTests: TealiumBaseTests {
    func test_create_completes_on_our_queue() {
        let initCompleted = expectation(description: "Tealium init completed")
        _ = createTealium { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            initCompleted.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }

    func test_onReady_completes_on_our_queue() {
        let onReadyCompleted = expectation(description: "Tealium onReady completed")
        let teal = createTealium()
        teal.onReady { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            onReadyCompleted.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }

    func test_track_arrives_to_dispatcher() {
        let dispatched = expectation(description: "The Dispatch is dispatched to the dispatcher")
        config.addModule(DefaultModuleFactory<MockDispatcher>())
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
            .setMappings([.from("tealium_event", to: "mapped_event")])
            .build()
        config.addModule(DefaultModuleFactory<MockDispatcher>(enforcedSettings: moduleSettings))
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

    func test_deinit_after_track() {
        let trackCompleted = expectation(description: "The track was completed")
        config.addModule(DefaultModuleFactory<MockDispatcher>())
        let helper = RetainCycleHelper(variable: createTealium())
        helper.strongVariable?.track("Event").subscribe { result in
            XCTAssertResultIsSuccess(result)
            trackCompleted.fulfill()
        }
        waitOnQueue(queue: instanceManager.queue, timeout: Self.defaultTimeout)
        helper.forceAndAssertObjectDeinit()
    }

    func test_flush_completes_on_our_queue() {
        let flushCompleted = expectation(description: "Tealium flush completed")
        let teal = createTealium()
        _ = teal.flushEventQueue().subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            flushCompleted.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }

    func test_module_shutdown_on_our_queue_when_tealium_deinit() {
        let initCompleted = expectation(description: "Tealium init completed")
        config.addModule(DefaultModuleFactory<MockDispatcher>())
        let helper = RetainCycleHelper(variable: createTealium { _ in
            initCompleted.fulfill()
        })
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
        let moduleShutdown = expectation(description: "Module is shutdown")
        MockDispatcher.onShutdown.subscribeOnce {
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            moduleShutdown.fulfill()
        }
        helper.forceAndAssertObjectDeinit()
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }

    func test_resetVisitorId_completes_on_our_queue() {
        let resetCompleted = expectation(description: "Reset visitorId completed")
        let teal = createTealium()
        teal.resetVisitorId().subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            resetCompleted.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }

    func test_clearStoredVisitorIds_completes_on_our_queue() {
        let clearCompleted = expectation(description: "Clear completed")
        let teal = createTealium()
        teal.clearStoredVisitorIds().subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            clearCompleted.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
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
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
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
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
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
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
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
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }

    func test_deeplink_wrapper_throws_errors_if_not_enabled() throws {
        let handleDeeplinkCompleted = expectation(description: "Handle deeplink completed")
        config.addModule(Modules.deepLink(forcingSettings: { enforcedSettings in
            enforcedSettings.setEnabled(false)
        }))
        let teal = createTealium()
        teal.deepLink.handle(link: try "https://www.tealium.com".asUrl(), referrer: nil).subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let object) = error as? TealiumError else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == DeepLinkModule.self)
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }

    func test_deeplink_wrapper_throws_errors_if_not_added() throws {
        let handleDeeplinkCompleted = expectation(description: "Handle deeplink completed")
        let teal = createTealium()
        teal.deepLink.handle(link: try "https://www.tealium.com".asUrl(), referrer: nil).subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let object) = error as? TealiumError else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == DeepLinkModule.self)
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
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
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }

    func test_trace_wrapper_throws_errors_if_not_enabled() throws {
        let joinTraceCompleted = expectation(description: "Join trace completed")
        config.addModule(Modules.trace(forcingSettings: { enforcedSettings in
            enforcedSettings.setEnabled(false)
        }))
        let teal = createTealium()
        teal.trace.join(id: "new trace").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let object) = error as? TealiumError else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == TraceModule.self)
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            joinTraceCompleted.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }

    func test_trace_wrapper_throws_errors_if_not_added() throws {
        let joinTraceCompleted = expectation(description: "Join trace completed")
        let teal = createTealium()
        teal.trace.join(id: "new trace").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let object) = error as? TealiumError else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertTrue(object == TraceModule.self)
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            joinTraceCompleted.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
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
        waitOnQueue(queue: queue, timeout: Self.defaultTimeout)
    }
}
