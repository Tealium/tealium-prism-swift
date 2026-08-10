//
//  ApplicationStatusListenerTests.swift
//  tealium-prism
//
//  Created by Denis Guzov on 20/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ApplicationStatusListenerTests: XCTestCase {
    let notificationCenter = NotificationCenter()
    var graceTimeInterval: TimeInterval = 1.0
    var queue: DispatchQueue {
        listener.queue.dispatchQueue
    }
    var qos = DispatchQoS.userInteractive
    lazy var listener = ApplicationStatusListener(graceTimeInterval: graceTimeInterval,
                                                  leeway: .nanoseconds(0),
                                                  queue: TealiumQueue(label: "testQueue",
                                                                      qos: qos),
                                                  notificationCenter: notificationCenter)

    var onApplicationStatus: Observable<ApplicationStatus> {
        listener.onApplicationStatus.subscribeOn(listener.queue)
    }

    func test_initialized_status_is_emitted_on_launch() {
        let emitted = expectation(description: "Initialized status emitted")
        onApplicationStatus.subscribeOnce { status in
            switch status.type {
            case .initialized:
                emitted.fulfill()
            default:
                return
            }
        }
        waitOnQueue(queue: listener.queue)
    }

    func test_cache_resized_after_grace_timeout() {
        let applicationStatusReceived = expectation(description: "Application status is received only once because it should be resized to 1")
        let subscriptionCalled = expectation(description: "Subscription called")
        graceTimeInterval = 0.01
        _ = listener
        notificationCenter.postBecomeActiveNotification()
        let automaticDisposer = AutomaticDisposer()
        queue.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.listener.onApplicationStatus.subscribe {_ in
                applicationStatusReceived.fulfill()
            }.addTo(automaticDisposer)
            subscriptionCalled.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func test_backgrounded_status_is_emitted() {
        let emitted = expectation(description: "Backgrounded status emitted")
        emitted.assertForOverFulfill = false
        emitted.expectedFulfillmentCount = 2
        let automaticDisposer = AutomaticDisposer()
        onApplicationStatus.subscribe { status in
            switch status.type {
            case .backgrounded, .initialized:
                emitted.fulfill()
            default:
                return
            }
        }.addTo(automaticDisposer)
        notificationCenter.postResignActiveNotification()
        waitOnQueue(queue: listener.queue)
    }

    func test_foregrounded_status_is_emitted() {
        let emitted = expectation(description: "Foregrounded status emitted")
        emitted.assertForOverFulfill = false
        emitted.expectedFulfillmentCount = 2
        let automaticDisposer = AutomaticDisposer()
        onApplicationStatus.subscribe { status in
            switch status.type {
            case .foregrounded, .initialized:
                emitted.fulfill()
            default:
                return
            }
        }.addTo(automaticDisposer)
        notificationCenter.postBecomeActiveNotification()
        waitOnQueue(queue: listener.queue)
    }

    func test_status_is_delivered_on_provided_queue() {
        let deliveredOnQueue = expectation(description: "Foregrounded status delivered on worker queue")
        let automaticDisposer = AutomaticDisposer()
        onApplicationStatus.subscribe { [queue] status in
            guard status.type == .foregrounded else { return }
            dispatchPrecondition(condition: .onQueue(queue))
            deliveredOnQueue.fulfill()
        }.addTo(automaticDisposer)
        notificationCenter.postBecomeActiveNotification()
        waitOnQueue(queue: listener.queue)
    }

    func test_post_does_not_block_the_posting_thread() {
        let delivered = expectation(description: "Status is eventually delivered on the worker queue")
        var statusDelivered = false
        // Use a utility-QoS queue (matching production `TealiumQueue.worker`) so blocking it
        // doesn't cause a priority inversion against the main thread that signals it.
        qos = .utility
        let blocker = DispatchSemaphore(value: 0)
        let automaticDisposer = AutomaticDisposer()
        onApplicationStatus.subscribe { status in
            guard status.type == .foregrounded else { return }
            statusDelivered = true
            delivered.fulfill()
        }.addTo(automaticDisposer)

        // Occupy the (serial) worker queue so any asynchronous delivery is queued behind this block.
        listener.queue.dispatchQueue.async { blocker.wait() }

        notificationCenter.postBecomeActiveNotification()
        // If posting were synchronous it would have delivered before this line (and deadlocked
        // on the blocked queue); reaching here with no delivery proves it did not block.
        XCTAssertFalse(statusDelivered, "Posting must not block the posting thread waiting for delivery")

        blocker.signal()
        waitOnQueue(queue: listener.queue)
    }

    func test_no_status_emitted_after_deinit() {
        let notEmitted = expectation(description: "No status emitted after deinit")
        notEmitted.isInverted = true
        var localListener: ApplicationStatusListener? = ApplicationStatusListener(
            graceTimeInterval: graceTimeInterval,
            leeway: .nanoseconds(0),
            queue: listener.queue,
            notificationCenter: notificationCenter
        )
        let automaticDisposer = AutomaticDisposer()
        localListener?.onApplicationStatus
            .subscribeOn(listener.queue)
            .subscribe { status in
                switch status.type {
                case .backgrounded, .foregrounded:
                    notEmitted.fulfill()
                default:
                    return
                }
            }.addTo(automaticDisposer)
        localListener = nil
        notificationCenter.postBecomeActiveNotification()
        notificationCenter.postResignActiveNotification()
        waitForDefaultTimeout()
    }

    func test_listener_can_be_deinitialized() {
        let helper = RetainCycleHelper(variable: ApplicationStatusListener(graceTimeInterval: 1.0))
        helper.forceAndAssertObjectDeinit()
    }
}
