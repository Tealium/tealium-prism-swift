//
//  InterceptorManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 19/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol InterceptorManagerProtocol: URLSessionTaskDelegate {
    init(interceptors: [RequestInterceptor], queue: DispatchQueue)
    func interceptResult(request: URLRequest, retryCount: Int, result: NetworkResult, shouldRetry: @escaping (Bool) -> Void)
}

/**
 * A class that handles some messages from the URLSession.
 * It forwards them to the interceptors along with some other internal network client messages.
 */
public class InterceptorManager: NSObject, InterceptorManagerProtocol {
    var interceptors: [RequestInterceptor]
    let queue: DispatchQueue
    public required init(interceptors: [RequestInterceptor], queue: DispatchQueue) {
        self.interceptors = interceptors
        self.queue = queue
    }

    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        TealiumSignposter.networking.event("URLSession WaitingForConnectivity", message: "\(task.originalRequest?.url?.absoluteString ?? "")")
        interceptors.forEach { interceptor in
            interceptor.waitingForConnectivity(task)
        }
    }

    /**
     * Forward the the result of a network request to all the interceptors and perform the `shouldRetry` callback based on the `RetryPolicy`returned by the interceptors.
     *
     * Retries are checked in reverse order as it's assumed that the latest added `RequestInterceptor` is a more specific interceptor that has a finer logic compared to the default ones that are added in the beginning.
     *
     * - Parameters:
     *    - request: the `URLRequest` that was just completed
     *    - retryCount: the number of times this request has been retried already (starts from 0)
     *    - result: the `NetworkResult` returned by the client
     *    - shouldRetry: the completion block, called when it's time to retry with `true` or immediately with `false` if the request should not be retried.
     */
    public func interceptResult(request: URLRequest, retryCount: Int, result: NetworkResult, shouldRetry: @escaping (Bool) -> Void) {
        let interceptors = self.interceptors
        for interceptor in interceptors {
            interceptor.didComplete(request,
                                    with: result)
        }
        var signposterState: SignpostStateWrapper?
        for interceptor in interceptors.reversed() {
            let retryPolicy = interceptor.shouldRetry(request,
                                                      retryCount: retryCount,
                                                      with: result)
            let shouldRetry = retryPolicy.shouldRetry(onQueue: queue) {
                TealiumSignposter.networking.endInterval("Retry Request", state: signposterState, "Waiting Retry: \(result)")
                shouldRetry(true)
            }
            if shouldRetry {
                signposterState = TealiumSignposter.networking.beginInterval("Retry Request", "Retrying: \(result)")
                return
            }
        }
        shouldRetry(false)
    }

}
