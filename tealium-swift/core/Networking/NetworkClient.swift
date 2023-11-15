//
//  NetworkClient.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/04/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol NetworkClientProtocol {
    func sendRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable
    func addInterceptor(_ interceptor: RequestInterceptor)
    func removeInterceptor(_ interceptor: RequestInterceptor)
}

/**
 * An HTTP client that sends `URLRequest`s via a `URLSession`.
 *
 * `URLRequest`s are sent as is and are retried according to the `RequestInterceptor`s logic when necessary.
 * `RequestInterceptor`s are also notified of other events concerning the request lifecycle.
 * Some of these events are related to the `NetworkClient` logic and some are just `URLSessionDelegate` events being forwarded.
 *
 * You should almost never create a new instance of this class but rather use the `shared` instance,
 * as it's configured with sensible defaults and using one `URLSession` comes with a series of optimizations.
 * If you need a new specific `RequestInterceptor` you can add it via the `addInterceptor` method instead of creating a new client.
 */
public class NetworkClient: NetworkClientProtocol {
    /// The shared instance created with the default configuration
    public static let shared: NetworkClient = NetworkClient()
    let session: URLSession
    private let queue: DispatchQueue
    let interceptorManager: InterceptorManagerProtocol
    /**
     * Creates and returns a new client.
     *
     * - Parameter configuration: the `NetworkConfiguration` used to instanciate the client.
     */
    public init(configuration: NetworkConfiguration = .default) {
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = configuration.queue
        let interceptorManager = configuration.interceptorManager
        self.interceptorManager = interceptorManager
        session = URLSession(configuration: configuration.sessionConfiguration,
                             delegate: interceptorManager,
                             delegateQueue: operationQueue)
        queue = configuration.queue
    }

    /**
     * Sends a `URLRequest` as is and completes with a `NetworkResult`. It returns a `TealiumDisposableProtocol` that can be disposed to cancel the request sent.
     *
     * Request lifecycle events are sent to the request interceptors and they are retried, when necessary, following the `RequestInterceptor` logic.
     *
     * - Parameters:
     *    - request: the `URLRequest` that is sent in the `URLSession.dataTask`
     *    - completion: the block that is called once the request is completed either with a success or with an unretriable error
     *
     * - Returns: the `TealiumDisposable` that can be used to dispose the request and cancel the dataTask and future retries.
     */
    public func sendRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        let signposterInterval = TealiumSignpostInterval(signposter: .networking, name: "Interceptable Request")
            .begin("Send Request: \(request)")
        return self.sendRetryableRequest(request) { result in
            signposterInterval.end("\(result)")
            completion(result)
        }
    }

    private func sendRetryableRequest(_ request: URLRequest, retryCount: Int = 0, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        let completion = SelfDestructingResultCompletion(completion: completion)
        let disposeContainer = TealiumDisposeContainer()
        self.sendBasicRequest(request) { result in
            self.interceptorManager.interceptResult(request: request, retryCount: retryCount, result: result) { [weak self] shouldRetry in
                guard let self = self, !disposeContainer.isDisposed else {
                    completion.fail(error: .cancelled)
                    return
                }
                if shouldRetry {
                    TealiumSignposter.networking.event("Retry", message: "\(retryCount + 1)")
                    self.sendRetryableRequest(request,
                                              retryCount: retryCount + 1,
                                              completion: completion.complete)
                    .addTo(disposeContainer)
                } else {
                    completion.complete(result: result)
                }
            }
        }.addTo(disposeContainer)
        return TealiumSubscription {
            self.queue.async {
                completion.fail(error: .cancelled)
                disposeContainer.dispose()
            }
        }
    }

    private func sendBasicRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> URLSessionDataTask {
        let signposterInterval = TealiumSignpostInterval(signposter: .networking, name: "Request")
            .begin("HTTP Request: \(request)")
        return session.send(request) { result in
            signposterInterval.end("\(result)")
            completion(result)
        }
    }

    /**
     * Adds a new interceptor
     *
     * - Parameter interceptor: the `RequestInterceptor` to be added
     */
    public func addInterceptor(_ interceptor: RequestInterceptor) {
        queue.async {
            self.interceptorManager.interceptors.append(interceptor)
        }
    }

    /**
     * Removes an interceptor
     *
     * - Parameter interceptor: the `RequestInterceptor` to be removed
     */
    public func removeInterceptor(_ interceptor: RequestInterceptor) {
        queue.async {
            self.interceptorManager.interceptors.removeAll { $0 === interceptor }
        }
    }
}
