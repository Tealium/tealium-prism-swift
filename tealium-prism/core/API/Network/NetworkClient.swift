//
//  NetworkClient.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/04/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Protocol for sending network requests and handling responses.
public protocol NetworkClient {
    /**
     * Sends a `URLRequest` as is and completes with a `NetworkResult`. It returns a `Disposable` that can be disposed to cancel the request sent.
     *
     * Request lifecycle events are sent to the request interceptors and they are retried, when necessary, following the `RequestInterceptor` logic.
     *
     * - Parameters:
     *    - request: the `URLRequest` that is sent in the `URLSession.dataTask`
     *    - completion: the block that is called once the request is completed: with a success, with a failure that the interceptors
     *    don't retry (including a retryable one once they stop retrying it, for example when `maxRetryCount` is reached),
     *    or with a `.cancelled` error if the returned `Disposable` is disposed first
     *
     * - Returns: the `Disposable` that can be used to dispose the request and cancel the dataTask and future retries.
     */
    func sendRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> any Disposable

    /**
     * Builds the given `RequestBuilder` and sends the resulting `URLRequest`, completing with a `NetworkResult`.
     *
     * Building happens in the client, so a malformed URL or any other build failure completes with
     * `.failure(.unknown)` and returns an already-disposed `Disposable` — the completion is *always* called.
     * This is the preferred entry point for custom (e.g. gzipped) requests: build with `RequestBuilder`
     * and hand the builder here.
     *
     * - Parameters:
     *    - request: the `RequestBuilder` describing the request to build and send.
     *    - completion: the block called once the request is completed, or immediately with a failure if it can't be built.
     *
     * - Returns: the `Disposable` that can be used to cancel the request.
     */
    func sendRequest(_ request: RequestBuilder, completion: @escaping (NetworkResult) -> Void) -> any Disposable

    /**
     * Creates a new `NetworkClient` from this instance which will use a specific logger.
     *
     * - parameter logger: The logger that will be used for this instance
     * - returns: A new `NetworkClient` instance.
     */
    func newClient(withLogger logger: LoggerProtocol) -> Self

    /**
     * Creates a new `NetworkClient` from this instance which will also use the given interceptors.
     *
     * The new client uses the same transport (`URLSession`) as this instance. Its interceptor list is
     * this instance's interceptors followed by the given ones:
     * - The given interceptors come after this instance's, so they are consulted first for retry decisions
     *   (see `RequestInterceptor.shouldRetry(_:consecutiveRetryCount:with:)`).
     * - `onAttemptResult` is called on all the interceptors in list order.
     *
     * This instance is unaffected: its requests keep going only through its own interceptors.
     *
     * - Parameters:
     *    - interceptors: The interceptors to add after this instance's interceptors.
     *    - maxRetryCount: the maximum number of retries of a request, whichever interceptor proposes them.
     *    `nil` means no limit. Not inherited from this instance.
     * - returns: A new `NetworkClient` instance.
     */
    func newClient(withAdditionalInterceptors interceptors: [RequestInterceptor], maxRetryCount: Int?) -> Self
}

public extension NetworkClient {
    /**
     * Creates a `NetworkHelperProtocol` that sends every request through this client.
     *
     * Typically used with a client derived with `newClient(withAdditionalInterceptors:)`,
     * to use the helper API with custom retry behavior.
     *
     * - Returns: a new `NetworkHelperProtocol` that sends its requests through this client.
     */
    func makeNetworkHelper() -> NetworkHelperProtocol {
        NetworkHelper(networkClient: self)
    }

    /// Same as `newClient(withAdditionalInterceptors:maxRetryCount:)`, with no limit on the number of retries.
    func newClient(withAdditionalInterceptors interceptors: [RequestInterceptor]) -> Self {
        newClient(withAdditionalInterceptors: interceptors, maxRetryCount: nil)
    }
}
