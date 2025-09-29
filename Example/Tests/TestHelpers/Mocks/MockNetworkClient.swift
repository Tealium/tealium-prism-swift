//
//  MockNetworkClient.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

class MockNetworkClient: NetworkClient {
    var interceptors = [RequestInterceptor]()
    var result: NetworkResult
    var resultMap: [String: NetworkResult] = [:]
    var requestDidSend: ((URLRequest) -> Void)?
    var delayBlock: (@escaping () -> Void) -> Void = { block in block() }
    init(result: NetworkResult) {
        self.result = result
    }

    func sendRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> Disposable {
        requestDidSend?(request)
        let subscription = Subscription { }
        delayBlock {
            guard !subscription.isDisposed else { return }
            let result = self.resultMap[request.url?.absoluteString ?? ""] ?? self.result
            completion(result)
        }
        return subscription
    }

    func addInterceptor(_ interceptor: RequestInterceptor) {
        interceptors.append(interceptor)
    }

    func removeInterceptor(_ interceptor: RequestInterceptor) {
        interceptors.removeAll(where: { $0 === interceptor })
    }

    func newClient(withLogger logger: any LoggerProtocol) -> Self {
        self
    }
}
