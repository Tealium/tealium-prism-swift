//
//  ConnectivityRetryInterceptor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A `RequestInterceptor` that makes a retryable failure wait for the SDK's connectivity signal while the connection is assumed unavailable.
 *
 * For a retryable error while `ConnectivityManagerProtocol.connectionAssumedAvailable` is `false`, `shouldRetry` returns `.afterEvent`,
 * which fires the next time `connectionAssumedAvailable` becomes `true`. Otherwise it returns `.doNotRetry`.
 */
public class ConnectivityRetryInterceptor: RequestInterceptor {
    let connectivityManager: ConnectivityManagerProtocol

    /// Creates a `ConnectivityRetryInterceptor` that waits on the given `ConnectivityManagerProtocol` for connectivity to return.
    /// - Parameter connectivityManager: the connectivity manager used to know when connectivity is assumed available again.
    public init(connectivityManager: ConnectivityManagerProtocol) {
        self.connectivityManager = connectivityManager
    }

    /// Ignored.
    public func onAttemptResult(_ request: URLRequest, retryCount: Int, with result: NetworkResult) { }

    public func shouldRetry(_ request: URLRequest, consecutiveRetryCount: Int, with response: NetworkResult) -> RetryPolicy {
        switch response {
        case .failure(let error) where error.isRetryable && !connectivityManager.connectionAssumedAvailable.value:
            return .afterEvent(
                connectivityManager.connectionAssumedAvailable
                    .filter { $0 }
                    .map { _ in }
            )
        default:
            return .doNotRetry
        }
    }
}
