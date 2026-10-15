//
//  RequestInterceptor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Protocol for intercepting and handling network requests and responses.
public protocol RequestInterceptor: AnyObject {
    /**
     * An attempt of a `URLRequest` completed with a `NetworkResult`.
     *
     * This event will be reported for each attempt, which means that if a request is retried it will be reported more than once for each call.
     * It's called on every interceptor before any retry decision is made, including when the client's `maxRetryCount` has been reached.
     *
     * - Parameters:
     *    - request: the `URLRequest` that was attempted
     *    - retryCount: the number of times this request had already been retried before this attempt, by any interceptor: 0 for the first attempt.
     *    - result: the `NetworkResult` that was created with the response from the server or with the error
     */
    func onAttemptResult(_ request: URLRequest, retryCount: Int, with result: NetworkResult)
    /**
     * The client is asking if a given `URLRequest` should be retried.
     *
     * Every interceptor must implement this method. Interceptors that only observe the completed requests return `.doNotRetry`.
     *
     * Interceptors are consulted in reverse order, so the most recently added one is asked first. The first `RetryPolicy`
     * other than `.doNotRetry` is used, which means `.doNotRetry` is "no opinion", not a veto: another interceptor may still retry the request.
     *
     * - Parameters:
     *    - request: the `URLRequest` to be retried
     *    - consecutiveRetryCount: the number of retries this interceptor proposed in a row right before this decision.
     *    It is 0 on the first failure and whenever the last retry was proposed by a different interceptor, so the count restarts,
     *    for example, after another interceptor waited for connectivity.
     *    - response: the `NetworkResult` for the last request sent
     */
    func shouldRetry(_ request: URLRequest, consecutiveRetryCount: Int, with response: NetworkResult) -> RetryPolicy
}
