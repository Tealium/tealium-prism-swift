//
//  RequestInterceptor.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol RequestInterceptor: AnyObject {
    /**
     * A `URLSessionTask` was put on hold by the `URLSession` while waiting for connectivity to come back
     *
     * - Parameter task: the `URLSessionTask` that was put on hold for connectivity
     */
    func waitingForConnectivity(_ task: URLSessionTask)
    /**
     * A `URLRequest` was completed with a `NetworkResult`
     *
     * This event will be reported for each completed data task, which means that if a request is retried it might be reported more than once for each call.
     *
     * - Parameters:
     *    - request: the `URLRequest` that was completed
     *    - response: the `NetworkResult` that was created with the response from the server or with the error
     */
    func didComplete(_ request: URLRequest, with response: NetworkResult)
    /**
     * The client is asking if a given `URLRequest` should be retried.
     *
     * - Parameters:
     *    - request: the `URLRequest` to be retried
     *    - retryCount: the amount of retries that have already been sent so far
     *    - response: the `NetworkResult` for the last request sent
     */
    func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy
}

public extension RequestInterceptor {
    func waitingForConnectivity(_ task: URLSessionTask) {}
    func didComplete(_ request: URLRequest, with response: NetworkResult) {}
    func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy { .doNotRetry }
}

/// An interceptor that retries all retriable errors
public class DefaultInterceptor: RequestInterceptor {
    let backoffPolicy: BackoffPolicy
    init(backoffPolicy: BackoffPolicy = ExponentialBackoff()) {
        self.backoffPolicy = backoffPolicy
    }

    public func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy {
        switch response {
        case .failure(let error) where error.isRetryable:
            return .afterDelay(backoffPolicy.backoff(forAttempt: retryCount + 1))
        default:
            return .doNotRetry
        }
    }
}
