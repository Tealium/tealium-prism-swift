//
//  NotificationCenter+observableTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 29/07/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class NotificationCenterObservableTests: XCTestCase {
    let notificationCenter = NotificationCenter()
    let notificationName = Notification.Name("TestNotification")

    func test_observable_emits_when_notification_is_posted() {
        let emitted = expectation(description: "Notification emitted")
        let observable = notificationCenter.observable(forName: notificationName)
        _ = observable.subscribe { _ in
            emitted.fulfill()
        }
        notificationCenter.post(name: notificationName, object: nil)
        waitForDefaultTimeout()
    }

    func test_observable_emits_multiple_times() {
        let emitted = expectation(description: "Notification emitted three times")
        emitted.expectedFulfillmentCount = 3
        let observable = notificationCenter.observable(forName: notificationName)
        _ = observable.subscribe { _ in
            emitted.fulfill()
        }
        notificationCenter.post(name: notificationName, object: nil)
        notificationCenter.post(name: notificationName, object: nil)
        notificationCenter.post(name: notificationName, object: nil)
        waitForDefaultTimeout()
    }

    func test_observable_is_cold_and_does_not_emit_notifications_posted_before_subscription() {
        let notEmitted = expectation(description: "Notification not emitted before subscription")
        notEmitted.isInverted = true
        notificationCenter.post(name: notificationName, object: nil)
        let observable = notificationCenter.observable(forName: notificationName)
        _ = observable.subscribe { _ in
            notEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_observable_does_not_emit_after_disposal() {
        let notEmitted = expectation(description: "Notification not emitted after disposal")
        notEmitted.isInverted = true
        let observable = notificationCenter.observable(forName: notificationName)
        let disposable = observable.subscribe { _ in
            notEmitted.fulfill()
        }
        disposable.dispose()
        notificationCenter.post(name: notificationName, object: nil)
        waitForDefaultTimeout()
    }

    func test_disposal_releases_the_captured_subscription_closure() {
        let released = expectation(description: "Captured references are released after disposal")
        let observable = notificationCenter.observable(forName: notificationName)
        // Scope `deinitTester` so the subscription closure is its only strong holder.
        let disposable: any Disposable = {
            let deinitTester = DeinitTester {
                released.fulfill()
            }
            return observable.subscribe { [deinitTester] _ in
                _ = deinitTester
            }
        }()
        disposable.dispose()
        waitForDefaultTimeout()
    }

    func test_observable_emits_the_correct_notification() {
        let emitted = expectation(description: "Correct notification emitted")
        let otherName = Notification.Name("OtherNotification")
        let observable = notificationCenter.observable(forName: notificationName)
        _ = observable.subscribe { notification in
            XCTAssertEqual(notification.name, self.notificationName)
            emitted.fulfill()
        }
        notificationCenter.post(name: otherName, object: nil)
        notificationCenter.post(name: notificationName, object: nil)
        waitForDefaultTimeout()
    }

    func test_multiple_subscriptions_each_receive_notifications() {
        let firstReceived = expectation(description: "First subscriber received notification")
        let secondReceived = expectation(description: "Second subscriber received notification")
        let observable = notificationCenter.observable(forName: notificationName)
        _ = observable.subscribe { _ in firstReceived.fulfill() }
        _ = observable.subscribe { _ in secondReceived.fulfill() }
        notificationCenter.post(name: notificationName, object: nil)
        waitForDefaultTimeout()
    }
}
