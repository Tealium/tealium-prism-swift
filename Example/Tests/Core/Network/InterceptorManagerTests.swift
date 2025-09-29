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
    let manager = InterceptorManager(interceptors: [], queue: TealiumQueue.main)
    func test_retry_after_delay_policy_should_retry() {
        let expectCompletion = expectation(description: "Completion interceptor should be called")
        let expectRetry = expectation(description: "Retry interceptor should be called")
        let expectInterceptResponse = expectation(description: "InterceptResponse completion should be called")
        manager.interceptors = [
            MockInterceptor(didComplete: { _, _ in expectCompletion.fulfill() },
                            shouldRetry: { _, retryCount, _ in
                                defer { expectRetry.fulfill() }
                                if retryCount == 0 {
                                    return .afterDelay(0)
                                }
                                return .doNotRetry
                            })
        ]

        manager.interceptResult(request: URLRequest(), retryCount: 0, result: .success(.successful())) { shouldRetry in
            XCTAssertTrue(shouldRetry)
            expectInterceptResponse.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_retry_after_event_policy_should_retry() {
        let expectCompletion = expectation(description: "Completion interceptor should be called")
        let expectRetry = expectation(description: "Retry interceptor should be called twice")
        let expectInterceptResponse = expectation(description: "InterceptResponse completion should be called")

        manager.interceptors = [
            MockInterceptor(didComplete: { _, _ in expectCompletion.fulfill() },
                            shouldRetry: { _, retryCount, _ in
                                defer { expectRetry.fulfill() }
                                if retryCount == 0 {
                                    return .afterEvent(.Just(()))
                                }
                                return .doNotRetry
                            })
        ]
        manager.interceptResult(request: URLRequest(), retryCount: 0, result: .success(.successful())) { shouldRetry in
            XCTAssertTrue(shouldRetry)
            expectInterceptResponse.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_waitingForConnectivity_interceptors_are_called_in_order() {
        let expectFirstCompletion = expectation(description: "First waitingForConnectivity interceptor should be called first")
        let expectSecondCompletion = expectation(description: "Second waitingForConnectivity interceptor should be called second")
        let firstInterceptor = MockInterceptor(waitingForConnectivity: { _ in expectFirstCompletion.fulfill() })
        let secondInterceptor = MockInterceptor(waitingForConnectivity: { _ in expectSecondCompletion.fulfill() })

        manager.interceptors = [
            firstInterceptor,
            secondInterceptor
        ]
        let task = URLSession.shared.dataTask(with: URLRequest())
        manager.urlSession(URLSession.shared, taskIsWaitingForConnectivity: task)
        wait(for: [expectFirstCompletion, expectSecondCompletion], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_completion_interceptors_are_called_in_order() {
        let expectFirstCompletion = expectation(description: "First completion interceptor should be called first")
        let expectSecondCompletion = expectation(description: "Second completion interceptor should be called second")
        let firstInterceptor = MockInterceptor(didComplete: { _, _ in expectFirstCompletion.fulfill() })
        let secondInterceptor = MockInterceptor(didComplete: { _, _ in expectSecondCompletion.fulfill() })

        manager.interceptors = [
            firstInterceptor,
            secondInterceptor
        ]
        manager.interceptResult(request: URLRequest(), retryCount: 0, result: .success(.successful())) { _ in }
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

        manager.interceptors = [
            firstInterceptor,
            secondInterceptor
        ]
        manager.interceptResult(request: URLRequest(), retryCount: 0, result: .success(.successful())) { _ in }
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

        manager.interceptors = [
            firstInterceptor,
            secondInterceptor,
            thirdInterceptor
        ]
        manager.interceptResult(request: URLRequest(), retryCount: 0, result: .success(.successful())) { shouldRetry in
            XCTAssertTrue(shouldRetry)
            expectInterceptResponse.fulfill()
        }
        wait(for: [expectThirdRetry, expectSecondRetry, expectInterceptResponse, expectFirstRetry], timeout: Self.defaultTimeout, enforceOrder: true)
    }
}
