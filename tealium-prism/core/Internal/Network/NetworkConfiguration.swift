//
//  NetworkConfiguration.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * The configuration of an `HTTPClient`.
 *
 * Stores the session configuration and queue used by the client, and the root `InterceptorManager`
 * built from the given interceptors and queue when the configuration is created.
 */
struct NetworkConfiguration {
    let sessionConfiguration: URLSessionConfiguration
    let queue: TealiumQueue
    let interceptorManager: InterceptorManager

    /// Creates a network configuration with the specified parameters.
    /// - Parameters:
    ///   - sessionConfiguration: The URL session configuration to use.
    ///   - interceptors: The request interceptors used to build the root `InterceptorManager`.
    ///   - queue: The queue for network operations.
    init(sessionConfiguration: URLSessionConfiguration,
         interceptors: [RequestInterceptor],
         queue: TealiumQueue) {
        self.sessionConfiguration = sessionConfiguration
        self.queue = queue
        self.interceptorManager = InterceptorManager(interceptors: interceptors, queue: queue)
    }
}

extension NetworkConfiguration {
    /// The default timeout, in seconds, for a single request.
    static let defaultRequestTimeout: TimeInterval = 30

    /// The default URL session configuration for network requests.
    static var defaultUrlSessionConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = defaultRequestTimeout
        return config
    }

    /// Only the shared `ConnectivityManager`, which feeds empirical connectivity.
    static let defaultInterceptors: [RequestInterceptor] = [
        ConnectivityManager.shared
    ]

    /// Creates and returns a new `NetworkConfiguration` with default parameters.
    static let `default` = NetworkConfiguration(sessionConfiguration: defaultUrlSessionConfiguration,
                                                interceptors: defaultInterceptors,
                                                queue: TealiumQueue.worker)
}
