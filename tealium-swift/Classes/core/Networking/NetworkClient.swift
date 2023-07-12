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
    public static let `default`: NetworkClient = NetworkClient()
    private let session: URLSession
    private let queue: DispatchQueue
    let interceptorManager: InterceptorManager
    
    public init(configuration: NetworkConfiguration = .default) {
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = configuration.queue
        let interceptorManager = InterceptorManager(interceptors: configuration.interceptors,
                                                    queue: configuration.queue)
        self.interceptorManager = interceptorManager
        session = URLSession(configuration: configuration.sessionConfiguration,
                             delegate: interceptorManager,
                             delegateQueue: operationQueue)
        // TODO: add tests that URLSession is created with the correct parameters
        queue = configuration.queue
    }
    
    public func sendRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposableProtocol {
        let state = TealiumSignposter.networking.beginInterval("Interceptable Request", "Send Request: \(request)")
        return self.sendRetryableRequest(request) { result in
            TealiumSignposter.networking.endInterval("Interceptable Request", state: state, "\(result)")
            completion(result)
        }
    }
    
    private func sendRetryableRequest(_ request: URLRequest, retryCount: Int = 0, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposableProtocol {
        let completion = SelfDestructingCompletion(completion: completion)
        let disposeContainer = TealiumDisposeContainer()
        self.sendBasicRequest(request) { result in
            self.queue.async {
                self.interceptorManager.interceptResponse(request: request, retryCount: retryCount, result: result) { [weak self] shouldRetry in
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
            self.queue.async {
                completion.fail(error: .cancelled)
                disposeContainer.dispose()
            }
        }
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
            self.interceptorManager.interceptors.append(interceptor)
        }
    }
    
    public func removeInterceptor(_ interceptor: RequestInterceptor) {
        queue.async {
            self.interceptorManager.interceptors.removeAll { $0 === interceptor }
        }
    }
}

// TODO: move to a separate file
class InterceptorManager: NSObject, URLSessionTaskDelegate {
    var interceptors: [RequestInterceptor]
    let queue: DispatchQueue
    init(interceptors: [RequestInterceptor], queue: DispatchQueue) {
        self.interceptors = interceptors
        self.queue = queue
    }
    
    // TODO: add tests for this method
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self.interceptors.forEach { interceptor in
            interceptor.didCollectMetrics(metrics, forTask: task)
        }
    }
    
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        TealiumSignposter.networking.event("URLSession WaitingForConnectivity", message: "\(task.originalRequest?.url?.absoluteString ?? "")")
        interceptors.forEach { interceptor in
            interceptor.waitingForConnectivity(task)
        }
    }
    
    func interceptResponse(request: URLRequest, retryCount: Int, result: NetworkResult, shouldRetry: @escaping (Bool) -> Void) {
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
