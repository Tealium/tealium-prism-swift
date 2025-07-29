//
//  MockNetworkClient.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockNetworkClient: NetworkClient {
    var interceptors = [RequestInterceptor]()
    var result: NetworkResult
    var requestDidSend: ((URLRequest) -> Void)?
    init(result: NetworkResult) {
        self.result = result
    }

    func sendRequest(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> Disposable {
        requestDidSend?(request)
        completion(result)
        return Subscription { }
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
