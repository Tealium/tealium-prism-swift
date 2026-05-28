//
//  MockNetworkHelper.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 15/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

extension ObjectResponse {
    static func successful(object: T) -> ObjectResponse<T> {
        ObjectResponse<T>(object: object,
                          urlResponse: HTTPURLResponse.successful())
    }
}

class MockNetworkHelper: NetworkHelperProtocol {
    var result: NetworkResult = NetworkResult.success(.successful())
    var delay: Int?
    var queue = DispatchQueue.main
    enum Requests {
        case get(URLConvertible, String?, [String: String]?)
        case post(URLConvertible, DataObject, [String: String]?)
    }

    @ReplaySubject<Requests>(cacheSize: 10)
    var requests

    func encodeResult<T: Codable>(_ resultObject: T) throws {
        let data = try Tealium.jsonEncoder.encode(resultObject)
        result = .success(.init(data: data, urlResponse: .successful()))
    }

    private func delayBlock(_ work: @escaping () -> Void) {
        if let delay = delay {
            if delay > 0 {
                queue.asyncAfter(deadline: .now() + .milliseconds(delay), execute: work)
            } else {
                queue.async(execute: work)
            }
        } else {
            work()
        }
    }

    func get(url: URLConvertible,
             etag: String?,
             additionalHeaders: [String: String]?,
             completion: @escaping (NetworkResult) -> Void) -> Disposable {
        let sub = Subscription { }
        delayBlock {
            guard !sub.isDisposed else {
                completion(.failure(.cancelled))
                return
            }
            self._requests.publish(.get(url, etag, additionalHeaders))
            completion(self.result)
        }
        return sub
    }

    func post(url: URLConvertible,
              body: DataObject,
              additionalHeaders: [String: String]?,
              completion: @escaping (NetworkResult) -> Void) -> Disposable {
        let sub = Subscription { }
        delayBlock {
            guard !sub.isDisposed else {
                completion(.failure(.cancelled))
                return
            }
            self._requests.publish(.post(url, body, additionalHeaders))
            completion(self.result)
        }
        return sub
    }
}
