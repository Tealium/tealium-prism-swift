//
//  MockInterceptorManager.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 19/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockInterceptorManager: NSObject, InterceptorManagerProtocol {
    var interceptors: [RequestInterceptor]

    var interceptResponseBlock: (_ retryCount: Int, _ result: NetworkResult, @escaping (Bool) -> Void) -> Void = { _, _, shouldRetry in
        shouldRetry(false)
    }

    @ToAnyObservable(BasePublisher<NetworkResult>())
    var onInterceptResponse: Observable<NetworkResult>

    @ToAnyObservable(BasePublisher<Void>())
    var onWaitingForConnectivity: Observable<Void>

    required init(interceptors: [RequestInterceptor], queue: DispatchQueue) {
        self.interceptors = interceptors
    }

    func interceptResult(request: URLRequest, retryCount: Int, result: NetworkResult, shouldRetry: @escaping (Bool) -> Void) {
        _onInterceptResponse.publish(result)
        interceptResponseBlock(retryCount, result, shouldRetry)
    }

    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        _onWaitingForConnectivity.publish(())
    }
}
