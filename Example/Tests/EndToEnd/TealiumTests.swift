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
    var modules = [any ModuleFactory]()
    lazy var config = TealiumConfig(account: "mockAccount",
                                    profile: "mockProfile",
                                    environment: "mockEnv",
                                    modules: modules,
                                    settingsFile: nil,
                                    settingsUrl: nil)

    func createTealium(completion: ((Tealium.InitializationResult) -> Void)? = nil) -> Tealium {
        Tealium.create(config: config, completion: completion)
    }

    override func tearDown() {
        super.tearDown()
        try? TealiumFileManager.deleteAtPath(path: TealiumFileManager.getTealiumApplicationFolder().path)
    }
}

final class TealiumTests: TealiumBaseTests {
    func test_create_completes_on_our_queue() {
        let initCompleted = expectation(description: "Tealium init completed")
        _ = createTealium { _ in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            initCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }

    func test_onReady_completes_on_our_queue() {
        let onReadyCompleted = expectation(description: "Tealium onReady completed")
        let teal = createTealium()
        teal.onReady { _ in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            onReadyCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }

    func test_track_arrives_to_dispatcher() {
        let dispatched = expectation(description: "The Dispatch is dispatched to the dispatcher")
        modules.append(DefaultModuleFactory<MockDispatcher>())
        let teal = createTealium()
        MockDispatcher.onDispatch.subscribeOnce { dispatches in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
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
        modules.append(DefaultModuleFactory<MockDispatcher>(enforcedSettings: moduleSettings))
        let teal = createTealium()
        MockDispatcher.onDispatch.subscribeOnce { dispatches in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            dispatched.fulfill()
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertEqual(dispatches.first?.payload, ["mapped_event": "Event"])
        }
        teal.track("Event")
        waitForLongTimeout()
    }

    func test_deinit_after_track() {
        let trackCompleted = expectation(description: "The track was completed")
        modules.append(DefaultModuleFactory<MockDispatcher>())
        let helper = RetainCycleHelper(variable: createTealium())
        helper.strongVariable?.track("Event").subscribe { result in
            XCTAssertResultIsSuccess(result)
            trackCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
        helper.forceAndAssertObjectDeinit()
    }

    func test_module_shutdown_on_our_queue_when_tealium_deinit() {
        let initCompleted = expectation(description: "Tealium init completed")
        modules.append(DefaultModuleFactory<MockDispatcher>())
        let helper = RetainCycleHelper(variable: createTealium { _ in
            initCompleted.fulfill()
        })
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
        let moduleShutdown = expectation(description: "Module is shutdown")
        MockDispatcher.onShutdown.subscribeOnce {
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            moduleShutdown.fulfill()
        }
        helper.forceAndAssertObjectDeinit()
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }

    func test_resetVisitorId_completes_on_our_queue() {
        let resetCompleted = expectation(description: "Reset visitorId completed")
        let teal = createTealium()
        teal.resetVisitorId().subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            resetCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }

    func test_clearStoredVisitorIds_completes_on_our_queue() {
        let clearCompleted = expectation(description: "Clear completed")
        let teal = createTealium()
        teal.clearStoredVisitorIds().subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            clearCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }

    func test_dataLayer_wrapper_works_on_our_queue() {
        let putCompleted = expectation(description: "Put completed")
        let dataUpdated = expectation(description: "Data updated")
        let teal = createTealium()
        _ = teal.dataLayer.onDataUpdated.subscribe { newData in
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            dataUpdated.fulfill()
            XCTAssertEqual(newData, ["some_key": "some_value"])
        }
        teal.dataLayer.put(key: "some_key", value: "some_value").subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            putCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }

    func test_deepLink_wrapper_works_on_our_queue() throws {
        let handleDeeplinkCompleted = expectation(description: "Handle deeplink completed")
        config.addModule(Modules.deepLink())
        config.addModule(Modules.trace())
        let teal = createTealium()
        teal.deepLink.handle(link: try "https://www.tealium.com".asUrl(), referrer: nil).subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
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
                XCTAssertTrue(object == DeepLinkHandlerModule.self)
            }
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
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
                XCTAssertTrue(object == DeepLinkHandlerModule.self)
            }
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            handleDeeplinkCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }

    func test_trace_wrapper_works_on_our_queue() throws {
        let joinTraceCompleted = expectation(description: "Join trace completed")
        config.addModule(Modules.trace())
        let teal = createTealium()
        teal.trace.join(id: "new trace").subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            joinTraceCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
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
                XCTAssertTrue(object == TraceManagerModule.self)
            }
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            joinTraceCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
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
                XCTAssertTrue(object == TraceManagerModule.self)
            }
            dispatchPrecondition(condition: .onQueue(TealiumQueue.worker.dispatchQueue))
            joinTraceCompleted.fulfill()
        }
        waitOnQueue(queue: .worker, timeout: Self.defaultTimeout)
    }
}
