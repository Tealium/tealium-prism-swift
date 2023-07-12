//
//  NetworkConfiguration.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//

import Foundation

public struct NetworkConfiguration {
    var sessionConfiguration: URLSessionConfiguration
    var interceptors: [RequestInterceptor]
    var queue: DispatchQueue
    public init(sessionConfiguration: URLSessionConfiguration = Self.defaultUrlSessionConfiguration,
                queue: DispatchQueue = tealiumQueue,
                interceptors: [RequestInterceptor] = Self.defaultInterceptors) {
        self.sessionConfiguration = sessionConfiguration
        self.queue = queue
        self.interceptors = interceptors
    }
}

extension NetworkConfiguration {
    public static var defaultUrlSessionConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return config
    }
    public static let defaultInterceptors: [RequestInterceptor] = [
        DefaultInterceptor(exponentialBackoffBase: 2, exponentialBackoffScale: 1),
        ConnectivityManager.shared
    ]
    
    public static var `default` : NetworkConfiguration {
        NetworkConfiguration()
    }
}
