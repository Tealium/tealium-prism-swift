//
//  InterceptorManagerTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 19/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class InterceptorManagerTests: XCTestCase {
    // Queue needs to be main or there are some race conditions
    let queue = TealiumQueue.main

    func test_retry_after_delay_policy_should_retry() {
        let expectCompletion = expectation(description: "Completion interceptor should be called")
        let expectRetry = expectation(description: "Retry interceptor should be called")
        let expectInterceptResponse = expectation(description: "InterceptResponse completion should be called")
        let manager = InterceptorManager(interceptors: [
            MockInterceptor(onAttemptResult: { _, _, _ in expectCompletion.fulfill() },
                            shouldRetry: { _, consecutiveRetryCount, _ in
                                defer { expectRetry.fulfill() }
                                if consecutiveRetryCount == 0 {
                                    return .afterDelay(0)
                                }
                                return .doNotRetry
                            })
        ], queue: queue)

        manager.interceptResult(request: URLRequest(), context: .initial, result: .success(.successful())) { next in
            switch next {
            case .some:
                expectInterceptResponse.fulfill()
            case .none:
                XCTFail("Expected a retry")
            }
        }
        waitForDefaultTimeout()
    }

    func test_retry_after_event_policy_should_retry() {
        let expectCompletion = expectation(description: "Completion interceptor should be called")
        let expectRetry = expectation(description: "Retry interceptor should be called twice")
        let expectInterceptResponse = expectation(description: "InterceptResponse completion should be called")

        let manager = InterceptorManager(interceptors: [
            MockInterceptor(onAttemptResult: { _, _, _ in expectCompletion.fulfill() },
                            shouldRetry: { _, consecutiveRetryCount, _ in
                                defer { expectRetry.fulfill() }
                                if consecutiveRetryCount == 0 {
                                    return .afterEvent(Observables.just(()))
                                }
                                return .doNotRetry
                            })
        ], queue: queue)
        manager.interceptResult(request: URLRequest(), context: .initial, result: .success(.successful())) { next in
            switch next {
            case .some:
                expectInterceptResponse.fulfill()
            case .none:
                XCTFail("Expected a retry")
            }
        }
        waitForDefaultTimeout()
    }

    func test_completion_interceptors_are_called_in_order() {
        let expectFirstCompletion = expectation(description: "First completion interceptor should be called first")
        let expectSecondCompletion = expectation(description: "Second completion interceptor should be called second")
        let firstInterceptor = MockInterceptor(onAttemptResult: { _, _, _ in expectFirstCompletion.fulfill() })
        let secondInterceptor = MockInterceptor(onAttemptResult: { _, _, _ in expectSecondCompletion.fulfill() })

        let manager = InterceptorManager(interceptors: [
            firstInterceptor,
            secondInterceptor
        ], queue: queue)
        manager.interceptResult(request: URLRequest(), context: .initial, result: .success(.successful())) { _ in }
        wait(for: [expectFirstCompletion, expectSecondCompletion], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_retry_interceptors_are_called_in_reverse_order() {
        let expectFirstRetry = expectation(description: "First retry interceptor should be called second")
        let expectSecondRetry = expectation(description: "Second retry interceptor should be called first")
        let firstInterceptor = MockInterceptor(shouldRetry: { _, _, _ in
            defer { expectFirstRetry.fulfill() }
            return .doNotRetry
        })
        let secondInterceptor = MockInterceptor(shouldRetry: { _, _, _ in
            defer { expectSecondRetry.fulfill() }
            return .doNotRetry
        })

        let manager = InterceptorManager(interceptors: [
            firstInterceptor,
            secondInterceptor
        ], queue: queue)
        manager.interceptResult(request: URLRequest(), context: .initial, result: .success(.successful())) { _ in }
        wait(for: [expectSecondRetry, expectFirstRetry], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_retry_interceptors_are_called_until_one_performs_retry() {
        let expectFirstRetry = expectation(description: "Retry interceptor should not be called as it is preceded by the second that retries")
        expectFirstRetry.isInverted = true
        let expectSecondRetry = expectation(description: "Retry interceptor should be called")
        let expectThirdRetry = expectation(description: "Retry interceptor should be called twice")
        let expectInterceptResponse = expectation(description: "InterceptResponse completion should be called")

        let firstInterceptor = MockInterceptor(shouldRetry: { _, _, _ in
            defer { expectFirstRetry.fulfill() }
            return .doNotRetry
        })
        let secondInterceptor = MockInterceptor(shouldRetry: { _, _, _ in
            defer { expectSecondRetry.fulfill() }
            return .afterDelay(0)
        })
        let thirdInterceptor = MockInterceptor(shouldRetry: { _, _, _ in
            defer { expectThirdRetry.fulfill() }
            return .doNotRetry
        })

        let manager = InterceptorManager(interceptors: [
            firstInterceptor,
            secondInterceptor,
            thirdInterceptor
        ], queue: queue)
        manager.interceptResult(request: URLRequest(), context: .initial, result: .success(.successful())) { next in
            switch next {
            case .some:
                expectInterceptResponse.fulfill()
            case .none:
                XCTFail("Expected a retry")
            }
        }
        wait(for: [expectThirdRetry, expectSecondRetry, expectInterceptResponse, expectFirstRetry], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_each_interceptor_receives_its_own_consecutive_retry_count() {
        // `interceptors.reversed()` is consulted first, so `other` (interceptors[1]) is asked before `winner` (interceptors[0]).
        // `other` must return `.doNotRetry` so `winner` is consulted too and each sees its own count.
        let expectOtherSeesTwo = expectation(description: "The interceptor that proposed the last 2 retries sees its own run of 2, but has no further opinion")
        let expectWinnerSeesZero = expectation(description: "The interceptor that never retried sees 0 and proposes this retry")
        let expectCompletion = expectation(description: "Completion has the winner with the consecutive count reset to 1")
        let winner = MockInterceptor(shouldRetry: { _, consecutiveRetryCount, _ in
            XCTAssertEqual(consecutiveRetryCount, 0)
            expectWinnerSeesZero.fulfill()
            return .afterDelay(0)
        })
        let other = MockInterceptor(shouldRetry: { _, consecutiveRetryCount, _ in
            XCTAssertEqual(consecutiveRetryCount, 2)
            expectOtherSeesTwo.fulfill()
            return .doNotRetry
        })
        let manager = InterceptorManager(interceptors: [winner, other], queue: queue)
        // A context as if `other` had already proposed 2 retries in a row.
        let context = RetryContext.initial
            .nextRetry(proposedBy: other)
            .nextRetry(proposedBy: other)
        manager.interceptResult(request: URLRequest(), context: context, result: .success(.successful())) { retryContext in
            XCTAssertIdentical(retryContext?.lastRetryInterceptor, winner)
            XCTAssertEqual(retryContext?.retryCount, context.retryCount + 1)
            XCTAssertEqual(retryContext?.consecutiveRetryCount, 1)
            expectCompletion.fulfill()
        }
        wait(for: [expectOtherSeesTwo, expectWinnerSeesZero, expectCompletion], timeout: Self.defaultTimeout)
    }

    func test_maxRetryCount_reached_calls_onAttemptResult_on_every_interceptor_but_asks_none_and_completes_with_nil() {
        let expectFirstCompletion = expectation(description: "First onAttemptResult is called")
        let expectSecondCompletion = expectation(description: "Second onAttemptResult is called")
        let expectNoRetryAsked = expectation(description: "No interceptor should be asked to retry")
        expectNoRetryAsked.isInverted = true
        let expectCompletion = expectation(description: "Completion receives nil")
        let firstInterceptor = MockInterceptor(onAttemptResult: { _, _, _ in expectFirstCompletion.fulfill() },
                                               shouldRetry: { _, _, _ in
                                                   expectNoRetryAsked.fulfill()
                                                   return .afterDelay(0)
                                               })
        let secondInterceptor = MockInterceptor(onAttemptResult: { _, _, _ in expectSecondCompletion.fulfill() },
                                                shouldRetry: { _, _, _ in
                                                    expectNoRetryAsked.fulfill()
                                                    return .afterDelay(0)
                                                })
        let manager = InterceptorManager(interceptors: [firstInterceptor, secondInterceptor], queue: queue, maxRetryCount: 2)
        let context = RetryContext.initial
            .nextRetry(proposedBy: firstInterceptor)
            .nextRetry(proposedBy: firstInterceptor)
        XCTAssertEqual(context.retryCount, 2)
        manager.interceptResult(request: URLRequest(), context: context, result: .success(.successful())) { next in
            XCTAssertNil(next)
            expectCompletion.fulfill()
        }
        wait(for: [expectFirstCompletion, expectSecondCompletion, expectCompletion], timeout: Self.defaultTimeout)
        wait(for: [expectNoRetryAsked], timeout: 0.1)
    }

    func test_onAttemptResult_receives_retryCount_0_for_a_fresh_context() {
        let expectOnAttemptResult = expectation(description: "onAttemptResult is called with retryCount 0")
        let manager = InterceptorManager(interceptors: [MockInterceptor(onAttemptResult: { _, retryCount, _ in
            XCTAssertEqual(retryCount, 0)
            expectOnAttemptResult.fulfill()
        })], queue: queue)
        manager.interceptResult(request: URLRequest(), context: .initial, result: .success(.successful())) { _ in }
        waitForDefaultTimeout()
    }

    func test_onAttemptResult_receives_the_total_retryCount_of_a_retried_context() {
        let expectOnAttemptResult = expectation(description: "onAttemptResult is called with retryCount 3")
        let interceptor = MockInterceptor(onAttemptResult: { _, retryCount, _ in
            XCTAssertEqual(retryCount, 3)
            expectOnAttemptResult.fulfill()
        })
        let manager = InterceptorManager(interceptors: [interceptor], queue: queue)
        let context = RetryContext.initial
            .nextRetry(proposedBy: interceptor)
            .nextRetry(proposedBy: interceptor)
            .nextRetry(proposedBy: interceptor)
        manager.interceptResult(request: URLRequest(), context: context, result: .success(.successful())) { _ in }
        waitForDefaultTimeout()
    }

    func test_onAttemptResult_receives_retryCount_when_maxRetryCount_is_reached() {
        let expectOnAttemptResult = expectation(description: "onAttemptResult is called with retryCount 2")
        let interceptor = MockInterceptor(onAttemptResult: { _, retryCount, _ in
            XCTAssertEqual(retryCount, 2)
            expectOnAttemptResult.fulfill()
        })
        let manager = InterceptorManager(interceptors: [interceptor], queue: queue, maxRetryCount: 2)
        let context = RetryContext.initial
            .nextRetry(proposedBy: interceptor)
            .nextRetry(proposedBy: interceptor)
        manager.interceptResult(request: URLRequest(), context: context, result: .success(.successful())) { next in
            XCTAssertNil(next)
        }
        waitForDefaultTimeout()
    }

    func test_onAttemptResult_receives_the_total_retryCount_not_the_consecutive_one() {
        let expectBoth = expectation(description: "Both interceptors receive the total retryCount")
        expectBoth.expectedFulfillmentCount = 2
        let onAttemptResult: MockInterceptor.OnAttemptResultBlock = { _, retryCount, _ in
            XCTAssertEqual(retryCount, 3)
            expectBoth.fulfill()
        }
        let firstInterceptor = MockInterceptor(onAttemptResult: onAttemptResult)
        let secondInterceptor = MockInterceptor(onAttemptResult: onAttemptResult)
        let manager = InterceptorManager(interceptors: [firstInterceptor, secondInterceptor], queue: queue)
        // first retried once, then second retried twice in a row: total 3, consecutive for second 2, for first 0.
        let context = RetryContext.initial
            .nextRetry(proposedBy: firstInterceptor)
            .nextRetry(proposedBy: secondInterceptor)
            .nextRetry(proposedBy: secondInterceptor)
        XCTAssertEqual(context.consecutiveRetryCount(for: secondInterceptor), 2)
        XCTAssertEqual(context.consecutiveRetryCount(for: firstInterceptor), 0)
        manager.interceptResult(request: URLRequest(), context: context, result: .success(.successful())) { _ in }
        waitForDefaultTimeout()
    }

    func test_completion_receives_nil_when_no_interceptor_retries() {
        let expectCompletion = expectation(description: "Completion receives nil")
        let manager = InterceptorManager(interceptors: [MockInterceptor(), MockInterceptor()], queue: queue)
        manager.interceptResult(request: URLRequest(), context: .initial, result: .success(.successful())) { next in
            XCTAssertNil(next)
            expectCompletion.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_newManager_uses_parent_interceptors_followed_by_additional_ones() {
        let first = MockInterceptor()
        let second = MockInterceptor()
        let third = MockInterceptor()
        let manager = InterceptorManager(interceptors: [first, second], queue: queue)
        let derived = manager.newManager(withAdditionalInterceptors: [third], maxRetryCount: nil)
        XCTAssertEqual(derived.interceptors.count, 3)
        XCTAssertIdentical(derived.interceptors[0], first)
        XCTAssertIdentical(derived.interceptors[1], second)
        XCTAssertIdentical(derived.interceptors[2], third)
    }

    func test_newManager_does_not_change_parent_interceptors() {
        let first = MockInterceptor()
        let second = MockInterceptor()
        let manager = InterceptorManager(interceptors: [first], queue: queue)
        _ = manager.newManager(withAdditionalInterceptors: [second], maxRetryCount: nil)
        XCTAssertEqual(manager.interceptors.count, 1)
        XCTAssertIdentical(manager.interceptors[0], first)
    }

    func test_newManager_uses_the_same_queue() {
        let manager = InterceptorManager(interceptors: [MockInterceptor()], queue: queue)
        let derived = manager.newManager(withAdditionalInterceptors: [MockInterceptor()], maxRetryCount: nil)
        XCTAssertIdentical(derived.queue, manager.queue)
    }

    func test_newManager_uses_the_given_maxRetryCount_and_does_not_inherit_the_parents() {
        let manager = InterceptorManager(interceptors: [MockInterceptor()], queue: queue, maxRetryCount: 5)
        let derived = manager.newManager(withAdditionalInterceptors: [MockInterceptor()], maxRetryCount: 2)
        XCTAssertEqual(manager.maxRetryCount, 5)
        XCTAssertEqual(derived.maxRetryCount, 2)
    }
}
