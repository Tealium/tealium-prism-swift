//
//  MockInterceptor.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 22/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumPrism
import XCTest

class MockInterceptor: RequestInterceptor {
    typealias OnAttemptResultBlock = (_ request: URLRequest, _ retryCount: Int, _ response: NetworkResult) -> Void
    typealias ShouldRetryBlock = (_ request: URLRequest, _ consecutiveRetryCount: Int, _ response: NetworkResult) -> RetryPolicy
    let onAttemptResult: OnAttemptResultBlock
    let shouldRetry: ShouldRetryBlock
    init(onAttemptResult: @escaping OnAttemptResultBlock = { _, _, _ in },
         shouldRetry: @escaping ShouldRetryBlock = { _, _, _ in .doNotRetry }) {
        self.onAttemptResult = onAttemptResult
        self.shouldRetry = shouldRetry
    }

    func onAttemptResult(_ request: URLRequest, retryCount: Int, with result: NetworkResult) {
        onAttemptResult(request, retryCount, result)
    }

    func shouldRetry(_ request: URLRequest, consecutiveRetryCount: Int, with response: NetworkResult) -> RetryPolicy {
        shouldRetry(request, consecutiveRetryCount, response)
    }
}

extension TealiumPrism.RetryPolicy: Swift.Equatable {
    /// Only for comparing during tests. Compares only the case and ignores the associated values.
    public static func == (lhs: RetryPolicy, rhs: RetryPolicy) -> Bool {
        switch (lhs, rhs) {
        case (.doNotRetry, .doNotRetry),
            (.afterEvent, .afterEvent),
            (.afterDelay, .afterDelay):
            return true
        default:
            return false
        }
    }
}

/// Extracts the delay of an `.afterDelay` policy, failing the test for any other policy.
///
/// The `RetryPolicy: Equatable` extension ignores the associated values, so it can't be used to check the delay.
func delay(of policy: RetryPolicy, file: StaticString = #filePath, line: UInt = #line) -> TimeInterval? {
    guard case let .afterDelay(delay) = policy else {
        XCTFail("Expected afterDelay, got \(policy)", file: file, line: line)
        return nil
    }
    return delay
}
