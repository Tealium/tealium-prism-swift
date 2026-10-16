//
//  ConnectivityRetryInterceptor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// Implementation of `RequestInterceptors.retryWhenConnected(connectivityManager:)`, see its documentation.
class ConnectivityRetryInterceptor: RequestInterceptor {
    let connectivityManager: ConnectivityManagerProtocol

    /// Creates a `ConnectivityRetryInterceptor` that waits on the given `ConnectivityManagerProtocol` for connectivity to return.
    /// - Parameter connectivityManager: the connectivity manager used to know when connectivity is assumed available again.
    init(connectivityManager: ConnectivityManagerProtocol) {
        self.connectivityManager = connectivityManager
    }

    /// Ignored.
    func onAttemptResult(_ request: URLRequest, retryCount: Int, with result: NetworkResult) { }

    func shouldRetry(_ request: URLRequest, consecutiveRetryCount: Int, with response: NetworkResult) -> RetryPolicy {
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
