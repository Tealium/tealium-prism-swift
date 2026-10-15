//
//  RetryContext.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Describes the retries already sent for a request.
 *
 * The interceptor manager advances it with `nextRetry(proposedBy:)` for the interceptor that proposed the retry.
 * Interceptors never see the context: they receive only their consecutive retry count.
 */
struct RetryContext {
    /// The retries already sent for this request, whichever interceptor proposed them.
    let retryCount: Int
    /// The interceptor that proposed the last retry. `nil` before the first retry.
    let lastRetryInterceptor: RequestInterceptor?
    /// The retries proposed in a row by `lastRetryInterceptor`, including the last one.
    let consecutiveRetryCount: Int

    private init(retryCount: Int, lastRetryInterceptor: RequestInterceptor?, consecutiveRetryCount: Int) {
        self.retryCount = retryCount
        self.lastRetryInterceptor = lastRetryInterceptor
        self.consecutiveRetryCount = consecutiveRetryCount
    }

    /// The context of a request that was never retried.
    static let initial = RetryContext(retryCount: 0, lastRetryInterceptor: nil, consecutiveRetryCount: 0)

    /// The consecutive retry count seen by `interceptor`: its current run if it proposed the last retry, 0 otherwise.
    func consecutiveRetryCount(for interceptor: RequestInterceptor) -> Int {
        guard let lastRetryInterceptor, lastRetryInterceptor === interceptor else {
            return 0
        }
        return consecutiveRetryCount
    }

    /// The next attempt's context, after `interceptor` proposed a retry.
    func nextRetry(proposedBy interceptor: RequestInterceptor) -> RetryContext {
        let newConsecutiveRetryCount = lastRetryInterceptor === interceptor ? consecutiveRetryCount + 1 : 1
        return RetryContext(retryCount: retryCount + 1,
                            lastRetryInterceptor: interceptor,
                            consecutiveRetryCount: newConsecutiveRetryCount)
    }
}
