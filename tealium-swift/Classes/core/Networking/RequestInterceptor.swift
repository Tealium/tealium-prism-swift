//
//  RequestInterceptor.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//

import Foundation

public protocol RequestInterceptor: AnyObject {
    func shouldDelay(_ request: URLRequest) -> DelayPolicy
    func didComplete(_ request: URLRequest, with response: NetworkResult)
    // Retries should be checked in reverse order as more specific retry interceptors may be added after the generic ones
    func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy
}

public extension RequestInterceptor {
    func shouldDelay(_ request: URLRequest) -> DelayPolicy { .doNotDelay }
    func didComplete(_ request: URLRequest, with response: NetworkResult) {}
    func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy { .doNotRetry }
}

public class BlockInterceptor: RequestInterceptor {
    typealias ShouldDelayBlock = (_ request: URLRequest) -> DelayPolicy
    typealias DidCompleteBlock = (_ request: URLRequest, _ response: NetworkResult) -> Void
    typealias ShouldRetryBlock = (_ request: URLRequest, _ retryCount: Int, _ response: NetworkResult) -> RetryPolicy
    let shouldDelay: ShouldDelayBlock
    let didComplete: DidCompleteBlock
    let shouldRetry: ShouldRetryBlock
    init(shouldDelay: @escaping ShouldDelayBlock = { _ in .doNotDelay}, didComplete: @escaping DidCompleteBlock = { _, _ in }, shouldRetry: @escaping ShouldRetryBlock = { _, _, _ in .doNotRetry }) {
        self.shouldDelay = shouldDelay
        self.didComplete = didComplete
        self.shouldRetry = shouldRetry
    }
    
    public func shouldDelay(_ request: URLRequest) -> DelayPolicy {
        shouldDelay(request)
    }
    
    public func didComplete(_ request: URLRequest, with response: NetworkResult) {
        didComplete(request, response)
    }
    
    public func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy {
        shouldRetry(request, retryCount, response)
    }
}

public class DefaultInterceptor: RequestInterceptor {
    let exponentialBackoffBase: Int
    let exponentialBackoffScale: Double
    init(exponentialBackoffBase: Int, exponentialBackoffScale: Double) {
        self.exponentialBackoffBase = exponentialBackoffBase
        self.exponentialBackoffScale = exponentialBackoffScale
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
            return .afterDelay(pow(Double(exponentialBackoffBase), Double(retryCount)) * exponentialBackoffScale)
        default:
            return .doNotRetry
        }
    }
}
