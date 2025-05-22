//
//  LifecycleWrapperTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 26/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class LifecycleWrapperTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let tracker = MockTracker()
    let autoDisposer = AutomaticDisposer()
    lazy var manager = ModulesManager(queue: queue)
    lazy var onManager: ReplaySubject<ModulesManager?> = ReplaySubject(initialValue: manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var wrapper = LifecycleWrapper(moduleProxy: ModuleProxy(onModulesManager: onManager.asObservable()))

    func context() -> TealiumContext {
        MockContext(modulesManager: manager,
                    config: config,
                    tracker: tracker,
                    databaseProvider: dbProvider,
                    queue: queue)
    }

    override func setUp() {
        config.modules = [TealiumModules.lifecycle()]
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [LifecycleModule.id: LifecycleSettingsBuilder().setAutoTrackingEnabled(false).build()]))
    }

    func test_launch_gets_tracked_on_calling_launch() {
        let launchTracked = expectation(description: "Launch has been tracked")
        tracker.onTrack.subscribeOnce({ dispatch in
            XCTAssertEqual(dispatch.name, "launch")
            launchTracked.fulfill()
        })
        wrapper.launch()
        waitOnQueue(queue: queue)
    }

    func test_launch_gets_tracked_with_passed_data_on_calling_launch() {
        let launchTracked = expectation(description: "Launch has been tracked with correct data")
        tracker.onTrack.subscribeOnce({ dispatch in
            XCTAssertEqual(dispatch.name, "launch")
            XCTAssertEqual(dispatch.payload.get(key: "customAttr"), 42)
            launchTracked.fulfill()
        })
        wrapper.launch(["customAttr": 42])
        waitOnQueue(queue: queue)
    }

    func test_sleep_gets_tracked_on_calling_sleep() {
        let sleepTracked = expectation(description: "Sleep has been tracked")
        tracker.onTrack.subscribe({ dispatch in
            if dispatch.name == "sleep" {
                sleepTracked.fulfill()
            }
        }).addTo(autoDisposer)
        wrapper.launch()
        wrapper.sleep()
        waitOnQueue(queue: queue)
    }

    func test_sleep_gets_tracked_with_passed_data_on_calling_sleep() {
        let sleepTracked = expectation(description: "Sleep has been tracked with correct data")
        tracker.onTrack.subscribe({ dispatch in
            if dispatch.name == "sleep" {
                XCTAssertEqual(dispatch.payload.get(key: "customAttr"), 42)
                sleepTracked.fulfill()
            }
        }).addTo(autoDisposer)
        wrapper.launch()
        wrapper.sleep(["customAttr": 42])
        waitOnQueue(queue: queue)
    }

    func test_wake_gets_tracked_on_calling_wake() {
        let wakeTracked = expectation(description: "Wake has been tracked")
        tracker.onTrack.subscribe({ dispatch in
            if dispatch.name == "wake" {
                wakeTracked.fulfill()
            }
        }).addTo(autoDisposer)
        wrapper.launch()
        wrapper.sleep()
        wrapper.wake()
        waitOnQueue(queue: queue)
    }

    func test_wake_gets_tracked_with_passed_data_on_calling_wake() {
        let wakeTracked = expectation(description: "Wake has been tracked with correct data")
        tracker.onTrack.subscribe({ dispatch in
            if dispatch.name == "wake" {
                XCTAssertEqual(dispatch.payload.get(key: "customAttr"), 42)
                wakeTracked.fulfill()
            }
        }).addTo(autoDisposer)
        wrapper.launch()
        wrapper.sleep()
        wrapper.wake(["customAttr": 42])
        waitOnQueue(queue: queue)
    }

    func test_launch_completion_gets_called_without_error_and_with_one_when_order_is_invalid() {
        let calledWithoutError = expectation(description: "Completion is called without error")
        let calledWithError = expectation(description: "Completion is called with error")
        _ = wrapper.launch(nil).subscribe { result in
            XCTAssertResultIsSuccess(result)
            calledWithoutError.fulfill()
        }
        _ = wrapper.launch(nil).subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error as? LifecycleError, LifecycleError.invalidEventOrder)
                calledWithError.fulfill()
            }
        }
        waitOnQueue(queue: queue)
    }

    func test_sleep_completion_gets_called_without_error_and_with_one_when_order_is_invalid() {
        let calledWithoutError = expectation(description: "Completion is called without error")
        let calledWithError = expectation(description: "Completion is called with error")
        wrapper.launch()
        _ = wrapper.sleep(nil).subscribe { result in
            XCTAssertResultIsSuccess(result)
            calledWithoutError.fulfill()
        }
        _ = wrapper.sleep(nil).subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error as? LifecycleError, LifecycleError.invalidEventOrder)
                calledWithError.fulfill()
            }
        }
        waitOnQueue(queue: queue)
    }

    func test_wake_completion_gets_called_without_error_and_with_one_when_order_is_invalid() {
        let calledWithoutError = expectation(description: "Completion is called without error")
        let calledWithError = expectation(description: "Completion is called with error")
        wrapper.launch()
        wrapper.sleep()
        _ = wrapper.wake(nil).subscribe { result in
            XCTAssertResultIsSuccess(result)
            calledWithoutError.fulfill()
        }
        _ = wrapper.wake(nil).subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error as? LifecycleError, LifecycleError.invalidEventOrder)
                calledWithError.fulfill()
            }
        }
        waitOnQueue(queue: queue)
    }
}
