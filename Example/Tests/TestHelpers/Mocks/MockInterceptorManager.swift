//
//  MockInterceptorManager.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 19/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable @preconcurrency import TealiumPrism

final class MockInterceptorManager: InterceptorManager {

    private let _onInterceptResponse = Subject<NetworkResult>()
    var onInterceptResponse: Observable<NetworkResult> { _onInterceptResponse.asObservable() }

    private let _onWaitingForConnectivity = Subject<Void>()
    var onWaitingForConnectivity: Observable<Void> { _onWaitingForConnectivity.asObservable() }

    override func interceptResult(request: URLRequest, retryCount: Int, result: NetworkResult, shouldRetry: @escaping (Bool) -> Void) {
        _onInterceptResponse.onNext(result)
        super.interceptResult(request: request, retryCount: retryCount, result: result, shouldRetry: shouldRetry)
    }

    override func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        _onWaitingForConnectivity.onNext(())
        super.urlSession(session, taskIsWaitingForConnectivity: task)
    }
}
