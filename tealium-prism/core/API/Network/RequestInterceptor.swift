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

/// What to do when a `Retry-After` header is above the maximum delay allowed for a retry.
public enum RetryAfterAboveMaxDelay {
    /// Stop proposing a retry for that failure: the interceptor returns `.doNotRetry` (no opinion), so the request
    /// completes with that failure unless another interceptor retries it.
    case giveUp
    /// Wait as long as the server asked, even beyond the maximum allowed delay.
    case wait
}

/// Factories for the built-in `RequestInterceptor`s that add retry behavior to a `NetworkClient`.
///
/// Pass the created interceptors to `NetworkClient.newClient(withAdditionalInterceptors:maxRetryCount:)`. Interceptors
/// are consulted in reverse order, so add `retryWhenConnected(connectivityManager:)` last: it is then asked first and,
/// while the connection is assumed unavailable, waits for it instead of letting `retryWithBackoff(...)` use up its attempts:
///
/// ```swift
/// let client = context.network.networkClient.newClient(withAdditionalInterceptors: [
///     RequestInterceptors.retryWithBackoff(maxAttempts: 3),
///     RequestInterceptors.retryWhenConnected(connectivityManager: context.network.connectivityManager)
/// ], maxRetryCount: 10)
/// ```
public enum RequestInterceptors { }

public extension RequestInterceptors {
    /**
     * Creates a `RequestInterceptor` that makes a retryable failure wait for the SDK's connectivity signal while the connection is assumed unavailable.
     *
     * For a retryable error while `ConnectivityManagerProtocol.connectionAssumedAvailable` is `false`, the interceptor retries
     * the next time `connectionAssumedAvailable` becomes `true`. Otherwise it expresses no opinion, so another interceptor may still retry.
     *
     * - Parameter connectivityManager: the connectivity manager used to know when connectivity is assumed available again.
     * - Returns: a new `RequestInterceptor`; it can be shared between clients.
     */
    static func retryWhenConnected(connectivityManager: ConnectivityManagerProtocol) -> RequestInterceptor {
        ConnectivityRetryInterceptor(connectivityManager: connectivityManager)
    }

    /**
     * Creates a `RequestInterceptor` that retries retryable failures with a full-jitter exponential backoff, and decides when to give up.
     *
     * - A failure is retryable when its `NetworkErrorType.isRetryable` is `true`, for example HTTP 429 and 503, or a lost connection.
     * - The `n`-th retry in a row proposed by this interceptor, counting from 0, waits a random delay between 0 and
     *   `min(maxDelay, base * 2^n)`. `base` is `throttlingBaseDelay` for HTTP 429 and `transientBaseDelay` otherwise.
     * - A `Retry-After` header is a minimum wait: the delay is the larger of the header and the backoff. The header can be a
     *   number of seconds or an HTTP date in the IMF-fixdate format, measured against the response's `Date` header when present
     *   so a skewed device clock doesn't matter. Other formats are ignored. For a header above `maxDelay`, the interceptor
     *   either stops proposing a retry or waits for it in full, depending on `retryAfterAboveMaxDelay`.
     * - `maxAttempts` counts consecutive attempts, including the one that just failed. The count, and with it the backoff,
     *   restarts when another interceptor proposed the last retry, for example after waiting for connectivity.
     *   To limit the total retries of a request, derive the client with a `maxRetryCount`.
     *
     * - Parameters:
     *    - maxAttempts: the maximum number of consecutive attempts, including the initial one. `nil` means there is no cap.
     *    - transientBaseDelay: the base delay, in seconds, for retryable failures other than HTTP 429.
     *    - throttlingBaseDelay: the base delay, in seconds, for HTTP 429 responses.
     *    - maxDelay: the longest backoff delay, in seconds. A `Retry-After` up to this long is waited as a minimum; a
     *    longer one is handled per `retryAfterAboveMaxDelay`.
     *    - retryAfterAboveMaxDelay: what to do when a `Retry-After` header asks for longer than `maxDelay`: `.giveUp`
     *    stops proposing a retry, so another interceptor may still retry, and `.wait` waits for the full header, with no
     *    upper bound.
     * - Returns: a new `RequestInterceptor`; it keeps no state, so it can be shared between clients.
     */
    static func retryWithBackoff(maxAttempts: Int? = 3,
                                 transientBaseDelay: TimeInterval = 0.1,
                                 throttlingBaseDelay: TimeInterval = 1,
                                 maxDelay: TimeInterval = 20,
                                 retryAfterAboveMaxDelay: RetryAfterAboveMaxDelay = .giveUp) -> RequestInterceptor {
        RetryableErrorInterceptor(maxAttempts: maxAttempts,
                                  transientBaseDelay: transientBaseDelay,
                                  throttlingBaseDelay: throttlingBaseDelay,
                                  maxDelay: maxDelay,
                                  retryAfterAboveMaxDelay: retryAfterAboveMaxDelay)
    }
}
