//
//  TealiumRepeatingTimerTests.swift
//  tealium-swift_Tests
//
//  Created by Denis Guzov on 09/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumRepeatingTimerTests: XCTestCase {
    func test_timer_calls_eventHandler() {
        let timerCompleted = expectation(description: "Event handler was called")
        let timer = TealiumRepeatingTimer(timeInterval: 0.01, repeating: .never, dispatchQueue: .main, eventHandler: {
            timerCompleted.fulfill()
        })
        timer.resume()
        waitForDefaultTimeout()
    }

    func test_timer_repeats_by_default() {
        let timerCompleted = expectation(description: "Event handler was called 2 times")
        timerCompleted.assertForOverFulfill = false
        timerCompleted.expectedFulfillmentCount = 2
        let timer = TealiumRepeatingTimer(timeInterval: 0.01, dispatchQueue: .main, eventHandler: {
            timerCompleted.fulfill()
        })
        timer.resume()
        waitForDefaultTimeout()
    }

    func test_timer_sets_repeat_with_timeInterval_by_default() {
        let timer = TealiumRepeatingTimer(timeInterval: 0.13, dispatchQueue: .main, eventHandler: { })
        XCTAssertEqual(timer.repeating, DispatchTimeInterval.milliseconds(130))
    }

    func test_timer_repeats_with_repeating_value_when_provided() {
        let timerCompletedFast = expectation(description: "Event handler should not complete twice fast enough")
        timerCompletedFast.isInverted = true
        timerCompletedFast.expectedFulfillmentCount = 2
        let timerCompletedOnRepeating = XCTestExpectation(description: "Event handler should complete twice on repeating time")
        timerCompletedOnRepeating.expectedFulfillmentCount = 2
        let timer = TealiumRepeatingTimer(timeInterval: 0.01, repeating: .milliseconds(200), dispatchQueue: .main, eventHandler: {
            timerCompletedFast.fulfill()
            timerCompletedOnRepeating.fulfill()
        })
        timer.resume()
        waitForDefaultTimeout()
        wait(for: [timerCompletedOnRepeating], timeout: 0.5)
    }

    func test_timer_does_not_repeat_when_repeating_is_never() {
        let timerCompleted = expectation(description: "Event handler was called only once")
        timerCompleted.expectedFulfillmentCount = 2
        timerCompleted.isInverted = true
        let timer = TealiumRepeatingTimer(timeInterval: 0.01, repeating: .never, dispatchQueue: .main, eventHandler: {
            timerCompleted.fulfill()
        })
        timer.resume()
        waitForDefaultTimeout()
    }

    func test_timer_can_be_deinitialized() {
        let neverTriggerTheHandler = expectation(description: "The handler should never be triggered")
        neverTriggerTheHandler.isInverted = true
        let helper = RetainCycleHelper(variable: TealiumRepeatingTimer(timeInterval: 0.1, repeating: .milliseconds(1), dispatchQueue: .main, eventHandler: {
            neverTriggerTheHandler.fulfill()
        }))
        helper.forceAndAssertObjectDeinit()
        waitForDefaultTimeout()
    }
}
