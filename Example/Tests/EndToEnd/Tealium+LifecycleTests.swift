//
//  Tealium+LifecycleTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 15/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumLifecycleTests: TealiumBaseTests {
    func test_lifecycle_wrapper_works_on_our_queue() throws {
        let lifecycleEventCompleted = expectation(description: "Lifecycle event completed")
        config.addModule(Modules.lifecycle(forcingSettings: { enforcedSettings in
            enforcedSettings.setAutoTrackingEnabled(false)
        }))
        let teal = createTealium()
        teal.lifecycle().launch().subscribe { result in
            XCTAssertResultIsSuccess(result)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            lifecycleEventCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_lifecycle_wrapper_throws_errors_if_not_enabled() throws {
        let lifecycleEventCompleted = expectation(description: "Lifecycle event completed")
        config.addModule(Modules.lifecycle(forcingSettings: { enforcedSettings in
            enforcedSettings.setEnabled(false)
        }))
        let teal = createTealium()
        teal.lifecycle().launch().subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error as? TealiumError else {
                    XCTFail("Error should be objectNotFound, but failed with \(error)")
                    return
                }
                XCTAssertTrue(module == LifecycleModule.self)
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            lifecycleEventCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_lifecycle_wrapper_throws_errors_if_not_added() throws {
        let lifecycleEventCompleted = expectation(description: "Lifecycle event completed")
        let teal = createTealium()
        teal.lifecycle().launch().subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error as? TealiumError else {
                    XCTFail("Error should be objectNotFound, but failed with \(error)")
                    return
                }
                XCTAssertTrue(module == LifecycleModule.self)
            }
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            lifecycleEventCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

#if os(iOS)
    func test_lifecycle_sleep_event_is_batched_with_previous_events_when_transformation_slows_execution() {
        let notificationCenter = NotificationCenter()
        config.appStatusListener = ApplicationStatusListener(notificationCenter: notificationCenter)
        config.addModule(Modules.lifecycle())
        config.addModule(MockDispatcher2.factory())
        config.addBarrier(Barriers.batching())
        config.addModule(Modules.deviceData(forcingSettings: { enforcedSettings in
            enforcedSettings.setDeviceNamesUrl("")
        }))
        let launchIsDispatched = expectation(description: "Launch is dispatched")
        MockDispatcher.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.map { $0.name }, ["launch"])
            launchIsDispatched.fulfill()
        }

        let teal = createTealium()
        waitForLongTimeout()

        let barrierClosed = expectation(description: "Wait for barrier to close after 0.2 seconds")
        queue.dispatchQueue.asyncAfter(deadline: .now() + .milliseconds(200)) {
            barrierClosed.fulfill()
        }
        waitForLongTimeout()

        let dispatchesAreBatched = expectation(description: "Dispatches are sent in one batch")
        MockDispatcher.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.map { $0.name }, ["event", "sleep"])
            dispatchesAreBatched.fulfill()
        }
        teal.track("event")
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        waitForLongTimeout()
    }
#endif
}
