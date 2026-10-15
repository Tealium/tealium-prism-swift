//
//  HTTPClient.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/04/23.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * An HTTP client that sends `URLRequest`s via a `URLSession`.
 *
 * `URLRequest`s are sent as is and are retried according to the `RequestInterceptor`s logic when necessary.
 * The client notifies the `RequestInterceptor`s of each request's result and asks them whether to retry it.
 *
 * You should almost never create a new instance of this class but rather use the `shared` instance,
 * as it's configured with sensible defaults and using one `URLSession` comes with a series of optimizations.
 * If you only need additional interceptors, derive a client with `newClient(withAdditionalInterceptors:)` instead of creating a new instance.
 */
final class HTTPClient: NetworkClient {
    /// The shared instance created with the default configuration
    static let shared: HTTPClient = HTTPClient(logger: nil)
    let session: URLSession
    private let queue: TealiumQueue
    let interceptorManager: InterceptorManager
    private let logger: LoggerProtocol?

    /**
     * Creates and returns a new client.
     *
     * - Parameter configuration: the `NetworkConfiguration` used to instantiate the client.
     */
    convenience init(configuration: NetworkConfiguration = .default, logger: LoggerProtocol?) {
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = configuration.queue.dispatchQueue
        let interceptorManager = configuration.interceptorManager
        self.init(session: URLSession(configuration: configuration.sessionConfiguration,
                                      delegate: nil,
                                      delegateQueue: operationQueue),
                  queue: configuration.queue,
                  interceptorManager: interceptorManager,
                  logger: logger)
    }

    required init(session: URLSession, queue: TealiumQueue, interceptorManager: InterceptorManager, logger: LoggerProtocol?) {
        self.session = session
        self.queue = queue
        self.interceptorManager = interceptorManager
        self.logger = logger
    }

    func sendRequest(_ request: RequestBuilder, completion: @escaping (NetworkResult) -> Void) -> any Disposable {
        do {
            logger?.trace(category: LogCategory.httpClient, "Building request\n\(request)")
            let urlRequest = try request.build()
            logger?.trace(category: LogCategory.httpClient, "Built request\n\(urlRequest)")
            return sendRequest(urlRequest, completion: completion)
        } catch {
            logger?.error(category: LogCategory.httpClient, "Failed to build request\n\(request)")
            completion(.failure(NetworkError(type: .unknown(error), urlResponse: nil)))
            return Disposables.disposed()
        }
    }

    func sendRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> any Disposable {
        logger?.trace(category: LogCategory.httpClient, "Sending request \(request)")
        let signposterInterval = TealiumSignpostInterval(signposter: .httpClient, name: "Interceptable Request")
            .begin("\(request)")
        return self.sendRetryableRequest(request) { [logger] result in
            signposterInterval.end("\(result)")
            logger?.log(level: result.logLevel(),
                        category: LogCategory.httpClient,
                        "Completed request. \(result.shortDescription())")
            logger?.trace(category: LogCategory.httpClient, "Response for request: \(request)\n\(result.longDescription())")
            completion(result)
        }
    }

    private func sendRetryableRequest(_ request: URLRequest, context: RetryContext = .initial, completion: @escaping (NetworkResult) -> Void) -> any Disposable {
        let completion = SelfDestructingResultCompletion(completion: completion)
        let disposeContainer = DisposableContainer()
        let task = self.sendBasicRequest(request) { result in
            self.interceptorManager.interceptResult(request: request, context: context, result: result) { [weak self] retryContext in
                guard let self, !disposeContainer.isDisposed else {
                    completion.fail(error: NetworkError(type: .cancelled, urlResponse: result.urlResponse))
                    return
                }
                // `nil` means the interceptors decided not to retry: this result is final.
                guard let retryContext else {
                    completion.complete(result: result)
                    return
                }
                TealiumSignposter.httpClient.event("Retry", "\(retryContext.retryCount)")
                self.logger?.trace(category: LogCategory.httpClient,
                                   "Retrying request \(request) Retry count: \(retryContext.retryCount)")
                self.sendRetryableRequest(request,
                                          context: retryContext,
                                          completion: completion.complete)
                .addTo(disposeContainer)
            }
        }
        return Subscription {
            self.queue.ensureOnQueue {
                completion.fail(error: NetworkError(type: .cancelled, urlResponse: nil))
                task.cancel()
                disposeContainer.dispose()
            }
        }
    }

    private func sendBasicRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> URLSessionDataTask {
        let signposterInterval = TealiumSignpostInterval(signposter: .httpClient, name: "Request")
            .begin("\(request)")
        return session.send(request) { result in
            signposterInterval.end("\(result)")
            completion(result)
        }
    }

    func newClient(withLogger logger: LoggerProtocol) -> Self {
        // swiftlint:disable:next explicit_init
        Self.init(session: session,
                  queue: queue,
                  interceptorManager: interceptorManager,
                  logger: logger)
    }

    func newClient(withAdditionalInterceptors interceptors: [RequestInterceptor], maxRetryCount: Int?) -> Self {
        // Derived clients share the session, and therefore its connection pool.
        // swiftlint:disable:next explicit_init
        return Self.init(session: session,
                         queue: queue,
                         interceptorManager: interceptorManager.newManager(withAdditionalInterceptors: interceptors, maxRetryCount: maxRetryCount),
                         logger: logger)
    }
}
