//
//  RetryContextTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class RetryContextTests: XCTestCase {
    func test_initial_has_zero_counts_and_no_last_interceptor() {
        let context = RetryContext.initial
        XCTAssertEqual(context.retryCount, 0)
        XCTAssertEqual(context.consecutiveRetryCount, 0)
        XCTAssertNil(context.lastRetryInterceptor)
    }

    func test_nextRetry_increments_retryCount() {
        let interceptor = MockInterceptor()
        let context = RetryContext.initial.nextRetry(proposedBy: interceptor)
        XCTAssertEqual(context.retryCount, 1)
        let secondContext = context.nextRetry(proposedBy: interceptor)
        XCTAssertEqual(secondContext.retryCount, 2)
    }

    func test_same_interceptor_retrying_twice_increments_consecutive_count() {
        let interceptor = MockInterceptor()
        let context = RetryContext.initial
            .nextRetry(proposedBy: interceptor)
            .nextRetry(proposedBy: interceptor)
        XCTAssertEqual(context.consecutiveRetryCount, 2)
        XCTAssertIdentical(context.lastRetryInterceptor, interceptor)
    }

    func test_different_interceptor_retrying_resets_consecutive_count_to_one() {
        let firstInterceptor = MockInterceptor()
        let secondInterceptor = MockInterceptor()
        let context = RetryContext.initial
            .nextRetry(proposedBy: firstInterceptor)
            .nextRetry(proposedBy: firstInterceptor)
            .nextRetry(proposedBy: secondInterceptor)
        XCTAssertEqual(context.retryCount, 3)
        XCTAssertEqual(context.consecutiveRetryCount, 1)
        XCTAssertIdentical(context.lastRetryInterceptor, secondInterceptor)
    }

    func test_consecutiveRetryCount_for_is_the_run_for_the_last_interceptor_and_zero_for_another() {
        let firstInterceptor = MockInterceptor()
        let secondInterceptor = MockInterceptor()
        let context = RetryContext.initial
            .nextRetry(proposedBy: firstInterceptor)
            .nextRetry(proposedBy: firstInterceptor)
            .nextRetry(proposedBy: firstInterceptor)
        XCTAssertEqual(context.consecutiveRetryCount(for: firstInterceptor), 3)
        XCTAssertEqual(context.consecutiveRetryCount(for: secondInterceptor), 0)
    }

    func test_consecutiveRetryCount_for_is_zero_on_the_initial_context() {
        let interceptor = MockInterceptor()
        XCTAssertEqual(RetryContext.initial.consecutiveRetryCount(for: interceptor), 0)
    }
}
