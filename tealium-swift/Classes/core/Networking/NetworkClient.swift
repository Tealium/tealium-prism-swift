//
//  NetworkClient.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/04/23.
//

import Foundation

public extension TealiumSignposter {
    static let networking = TealiumSignposter(category: "Networking")
}

public struct NetworkResponse {
    public let data: Data
    public let urlResponse: HTTPURLResponse
}

public typealias NetworkResult = Result<NetworkResponse, NetworkError>

public protocol NetworkClientProtocol {
    func sendRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposableProtocol
    func addInterceptor(_ interceptor: RequestInterceptor)
    func removeInterceptor(_ interceptor: RequestInterceptor)
}

public class NetworkClient: NetworkClientProtocol {
    static let defaultUrlSession = URLSession.shared
    static let defaultInterceptors = [DefaultInterceptor(exponentialBackoffBase: 2, exponentialBackoffScale: 1)]
    public static let `default`: NetworkClient = NetworkClient(configuration: NetworkConfiguration(session: defaultUrlSession,
                                                                                                  interceptors: defaultInterceptors))
    private let session: URLSession
    private(set) var interceptors: [RequestInterceptor]
    private let queue: DispatchQueue
    
    public init(configuration: NetworkConfiguration) {
        session = configuration.session
        interceptors = configuration.interceptors
        queue = configuration.queue
    }
    
    public func sendRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposableProtocol {
        let state = TealiumSignposter.networking.beginInterval("Interceptable Request", "Send Request: \(request)")
        let completion = SelfDestructingCompletion<NetworkResponse, NetworkError>(completion: { result in
            TealiumSignposter.networking.endInterval("Interceptable Request", state: state, "\(result)")
            completion(result)
        })
        let disposeContainer = TealiumDisposeContainer()
        interceptRequest(request: request) {
            guard !disposeContainer.isDisposed else {
                completion.fail(error: .cancelled)
                return
            }
            self.sendRetryableRequest(request, completion: completion.complete(result:))
                .toDisposeContainer(disposeContainer)
        }
        return TealiumSubscription {
            self.queue.async {
                completion.fail(error: .cancelled)
                disposeContainer.dispose()
            }
        }
    }
    
    private func sendRetryableRequest(_ request: URLRequest, retryCount: Int = 0, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposableProtocol {
        let completion = SelfDestructingCompletion(completion: completion)
        let disposeContainer = TealiumDisposeContainer()
        self.sendBasicRequest(request) { result in
            self.queue.async {
                self.interceptResponse(request: request, retryCount: retryCount, result: result) { [weak self] shouldRetry in
                    guard let self = self, !disposeContainer.isDisposed else {
                        completion.fail(error: .cancelled)
                        return
                    }
                    if shouldRetry {
                        TealiumSignposter.networking.event("Retry", message: "\(retryCount+1)")
                        self.sendRetryableRequest(request,
                                                      retryCount: retryCount+1,
                                                      completion: completion.complete)
                        .toDisposeContainer(disposeContainer)
                    } else {
                        completion.complete(result: result)
                    }
                }
            }
        }.toDisposeContainer(disposeContainer)
        return TealiumSubscription {
            completion.fail(error: .cancelled)
            disposeContainer.dispose()
        }
    }
    
    private func interceptRequest(request: URLRequest, completion: @escaping () -> Void) {
        var signposterState: SignpostStateWrapper?
        for interceptor in interceptors.reversed() {
            let delayPolicy = interceptor.shouldDelay(request)
            let shouldDelay = delayPolicy.shouldDelay(onQueue: queue) {
                TealiumSignposter.networking.endInterval("Delay Request", state: signposterState, "Waiting Send: \(request)")
                completion()
            }
            if shouldDelay {
                signposterState = TealiumSignposter.networking.beginInterval("Delay Request", "Delayed: \(request)")
                return
            }
        }
        completion()
    }
    
    private func interceptResponse(request: URLRequest, retryCount: Int, result: NetworkResult, shouldRetry: @escaping (Bool) -> Void) {
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
    
    private func sendBasicRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> URLSessionDataTask {
        let state = TealiumSignposter.networking.beginInterval("Request", "HTTP Request: \(request)")
        return session.send(request) { result in
            TealiumSignposter.networking.endInterval("Request", state: state, "\(result)")
            completion(result)
        }
    }
    
    public func addInterceptor(_ interceptor: RequestInterceptor) {
        queue.async {
            self.interceptors.append(interceptor)
        }
    }
    
    public func removeInterceptor(_ interceptor: RequestInterceptor) {
        queue.async {
            self.interceptors.removeAll { $0 === interceptor }
        }
    }
}
