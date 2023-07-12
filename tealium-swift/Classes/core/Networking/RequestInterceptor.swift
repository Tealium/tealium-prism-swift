//
//  RequestInterceptor.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//

import Foundation

public protocol RequestInterceptor: AnyObject {
    func waitingForConnectivity(_ task: URLSessionTask)
    func didCollectMetrics(_ metrics: URLSessionTaskMetrics, forTask task: URLSessionTask)
    func didComplete(_ request: URLRequest, with response: NetworkResult)
    // Retries should be checked in reverse order as more specific retry interceptors may be added after the generic ones
    func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy
}

public extension RequestInterceptor {
    func waitingForConnectivity(_ task: URLSessionTask) {}
    func didCollectMetrics(_ metrics: URLSessionTaskMetrics, forTask task: URLSessionTask) {}
    func didComplete(_ request: URLRequest, with response: NetworkResult) {}
    func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy { .doNotRetry }
}

public class BlockInterceptor: RequestInterceptor {
    typealias WaitingForConnectivityBlock = (_ task: URLSessionTask) -> Void
    typealias DidCompleteBlock = (_ request: URLRequest, _ response: NetworkResult) -> Void
    typealias ShouldRetryBlock = (_ request: URLRequest, _ retryCount: Int, _ response: NetworkResult) -> RetryPolicy
    let waitingForConnectivityBlock: WaitingForConnectivityBlock
    let didComplete: DidCompleteBlock
    let shouldRetry: ShouldRetryBlock
    init(waitingForConnectivity: @escaping WaitingForConnectivityBlock = { _ in }, didComplete: @escaping DidCompleteBlock = { _, _ in }, shouldRetry: @escaping ShouldRetryBlock = { _, _, _ in .doNotRetry }) {
        self.waitingForConnectivityBlock = waitingForConnectivity
        self.didComplete = didComplete
        self.shouldRetry = shouldRetry
    }
    
    public func waitingForConnectivity(_ task: URLSessionTask) {
        waitingForConnectivityBlock(task)
    }
    
    public func didComplete(_ request: URLRequest, with response: NetworkResult) {
        didComplete(request, response)
    }
    
    public func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy {
        shouldRetry(request, retryCount, response)
    }
}

public class DefaultInterceptor: RequestInterceptor {
    let exponentialBackoffBase: Double
    let exponentialBackoffScale: Double
    let maximumBackoff: Double
    init(exponentialBackoffBase: Double = 2, exponentialBackoffScale: Double = 1, maximumBackoff: Double = 150) {
        self.exponentialBackoffBase = exponentialBackoffBase
        self.exponentialBackoffScale = exponentialBackoffScale
        self.maximumBackoff = maximumBackoff
    }
    
    public func didComplete(_ request: URLRequest, with response: NetworkResult) {
        // TODO: change with a logger instance?
        var text = "NetworkRequest \(request) "
        switch response {
        case .failure(let error):
            text += "failed with \(error.localizedDescription)"
        case .success(let response):
            text += "succeded with \(response.urlResponse.statusCode) status code"
        }
        print(text)
    }
    
    public func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy {
        switch response {
        case .failure(let error) where error.isRetryable:
            return .afterDelay(min(pow(exponentialBackoffBase, Double(retryCount)) * exponentialBackoffScale, maximumBackoff))
        default:
            return .doNotRetry
        }
    }
}
