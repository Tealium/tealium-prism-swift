//
//  MockInterceptorManager.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 19/06/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
@testable import tealium_swift

class MockInterceptorManager: NSObject, InterceptorManagerProtocol {
    var interceptors: [RequestInterceptor]
    
    var interceptResponseBlock: (_ retryCount: Int, _ result: NetworkResult, @escaping (Bool) -> Void) -> Void = { _, _, shouldRetry in
        shouldRetry(false)
    }
    
    @ToAnyObservable(TealiumPublisher<NetworkResult>())
    var onInterceptResponse: TealiumObservable<NetworkResult>
    
    @ToAnyObservable(TealiumPublisher<Void>())
    var onWaitingForConnectivity: TealiumObservable<Void>
    
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
