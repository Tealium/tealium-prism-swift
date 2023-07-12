//
//  MockInterceptor.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 22/06/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
import tealium_swift

class MockInterceptor: RequestInterceptor {
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
    
    func waitingForConnectivity(_ task: URLSessionTask) {
        waitingForConnectivityBlock(task)
    }
    
    func didComplete(_ request: URLRequest, with response: NetworkResult) {
        didComplete(request, response)
    }
    
    func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy {
        shouldRetry(request, retryCount, response)
    }
}
