//
//  InterceptorManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 19/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A class that forwards the result of each request to the interceptors and resolves the retry decision.
 */
final class InterceptorManager {
    let interceptors: [RequestInterceptor]
    let queue: TealiumQueue
    /// The maximum number of retries of a request, whichever interceptor proposes them. `nil` means no limit.
    let maxRetryCount: Int?
    /// Initializes the interceptor manager with the provided interceptors, queue and optional retry limit.
    init(interceptors: [RequestInterceptor], queue: TealiumQueue, maxRetryCount: Int? = nil) {
        self.interceptors = interceptors
        self.queue = queue
        self.maxRetryCount = maxRetryCount
    }

    /**
     * Forward the result of a network request to all the interceptors and resolve the retry decision.
     *
     * `onAttemptResult` is called on every interceptor in list order. Then, unless `maxRetryCount` has been reached (in which
     * case no interceptor is asked and the request is not retried), interceptors are asked in reverse order
     * (see `RequestInterceptor.shouldRetry(_:consecutiveRetryCount:with:)`). Each interceptor sees its own consecutive
     * retry count via `RetryContext.consecutiveRetryCount(for:)`.
     *
     * - Parameters:
     *    - request: the `URLRequest` that was just completed
     *    - context: the `RetryContext` describing the retries already sent for this request
     *    - result: the `NetworkResult` returned by the client
     *    - completion: called with the next attempt's context once it's time to retry, or with `nil`, possibly immediately,
     *    when the request must not be retried.
     */
    func interceptResult(request: URLRequest, context: RetryContext, result: NetworkResult, completion: @escaping (RetryContext?) -> Void) {
        for interceptor in interceptors {
            interceptor.onAttemptResult(request,
                                        retryCount: context.retryCount,
                                        with: result)
        }
        if let maxRetryCount, context.retryCount >= maxRetryCount {
            completion(nil)
            return
        }
        for interceptor in interceptors.reversed() {
            let retryPolicy = interceptor.shouldRetry(request,
                                                      consecutiveRetryCount: context.consecutiveRetryCount(for: interceptor),
                                                      with: result)
            // Cleared when the wait ends, so a policy that retries immediately never leaves an interval open.
            var interval: TealiumSignpostInterval? = TealiumSignpostInterval(signposter: .networking, name: "Retry Request")
            let willRetry = retryPolicy.shouldRetry(onQueue: queue) {
                interval?.end("Waiting Retry: \(result)")
                interval = nil
                completion(context.nextRetry(proposedBy: interceptor))
            }
            if willRetry {
                _ = interval?.begin("Retrying: \(result)")
                return
            }
        }
        completion(nil)
    }

    /**
     * Creates a new interceptor manager which will also use the given interceptors.
     *
     * The new manager's interceptors are this manager's interceptors followed by the given ones, and it uses the same queue.
     *
     * This manager is unaffected: it keeps using only its own interceptors.
     *
     * - Parameters:
     *    - interceptors: the interceptors to append to this manager's interceptors.
     *    - maxRetryCount: the maximum number of retries of a request, whichever interceptor proposes them. `nil` means no limit.
     *    Not inherited from this manager.
     * - Returns: a new manager using this manager's interceptors followed by the given ones.
     */
    func newManager(withAdditionalInterceptors interceptors: [RequestInterceptor], maxRetryCount: Int?) -> InterceptorManager {
        InterceptorManager(interceptors: self.interceptors + interceptors, queue: queue, maxRetryCount: maxRetryCount)
    }
}
