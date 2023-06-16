//
//  NetworkConfiguration.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//

import Foundation

public struct NetworkConfiguration {
    var session: URLSession
    var interceptors: [RequestInterceptor]
    var queue: DispatchQueue
    public init(session: URLSession, queue: DispatchQueue = tealiumQueue, interceptors: [RequestInterceptor] = []) {
        self.session = session
        self.queue = queue
        self.interceptors = interceptors
    }
}
