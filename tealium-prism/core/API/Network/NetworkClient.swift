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
     *    - completion: the block that is called once the request is completed either with a success or with an unretryable error
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
}
