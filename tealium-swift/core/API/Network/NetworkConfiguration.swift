//
//  NetworkConfiguration.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * The configuration that is used by the `NetworkClient` to customize it's behavior.
 *
 * You almost never need to change this as most of the Networking should happen via the shared `NetworkingClient` instance.
 * If you need to add new interceptors you can do that directly on the `NetworkClient`.
 *
 * In case you really want to create a new client, start off from the `NetworkConfiguration.default`and edit it.
 * Make sure to use a `URLSessionConfiguration` without cache and make sure to have at least the default interceptors.
 */
public struct NetworkConfiguration {
    var sessionConfiguration: URLSessionConfiguration
    var interceptors: [RequestInterceptor]
    var queue: TealiumQueue
    var interceptorManagerFactory: InterceptorManagerProtocol.Type

    public init(sessionConfiguration: URLSessionConfiguration,
                interceptors: [RequestInterceptor],
                interceptorManagerFactory: InterceptorManagerProtocol.Type = InterceptorManager.self,
                queue: TealiumQueue) {
        self.sessionConfiguration = sessionConfiguration
        self.queue = queue
        self.interceptors = interceptors
        self.interceptorManagerFactory = interceptorManagerFactory
    }

    var interceptorManager: InterceptorManagerProtocol {
        interceptorManagerFactory.init(interceptors: interceptors,
                                       queue: queue)
    }
}

public extension NetworkConfiguration {
    static var defaultUrlSessionConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return config
    }

    static let defaultInterceptors: [RequestInterceptor] = [
        DefaultInterceptor(),
        ConnectivityManager.shared
    ]

    /// Creates and returns a new `NetworkConfiguration` with default parameters.
    static var `default`: NetworkConfiguration {
        NetworkConfiguration(sessionConfiguration: defaultUrlSessionConfiguration,
                             interceptors: defaultInterceptors,
                             queue: TealiumQueue.worker)
    }
}
