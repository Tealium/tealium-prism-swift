//
//  MockNetworkHelper.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 15/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

extension JSONResponse {
    static func successful(json: [String: Any]) -> Self {
        JSONResponse(json: json,
                     urlResponse: HTTPURLResponse.successful())
    }
}

extension ObjectResponse {
    static func successful(object: T) -> ObjectResponse<T> {
        ObjectResponse<T>(object: object,
                          urlResponse: HTTPURLResponse.successful())
    }
}

class MockNetworkHelper: NetworkHelperProtocol {
    enum MockError: Error {
        case failedToConvertToExpectedResultType
    }
    var result: NetworkResult = NetworkResult.success(.successful())
    var jsonResult: JSONResult = JSONResult.success(.successful(json: [:]))
    var codableResult: ObjectResult<Any> = ObjectResult.success(.successful(object: ()))
    var delay: Int?
    var queue = DispatchQueue.main
    enum Requests {
        case get(URLConvertible, String?)
        case post(URLConvertible, [String: Any])
    }

    @ToAnyObservable(TealiumReplaySubject(cacheSize: 10))
    var requests: TealiumObservable<Requests>

    private func delayBlock(_ work: @escaping () -> Void) {
        if let delay = delay {
            queue.asyncAfter(deadline: .now() + .milliseconds(delay), execute: work)
        } else {
            work()
        }
    }

    func get(url: URLConvertible, etag: String?, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        let sub = TealiumSubscription { }
        delayBlock {
            guard !sub.isDisposed else {
                completion(.failure(.cancelled))
                return
            }
            self._requests.publish(.get(url, etag))
            completion(self.result)
        }
        return sub
    }

    func getJsonAsDictionary(url: URLConvertible, etag: String?, completion: @escaping (JSONResult) -> Void) -> TealiumDisposable {
        let sub = TealiumSubscription { }
        delayBlock {
            guard !sub.isDisposed else {
                completion(.failure(.cancelled))
                return
            }
            self._requests.publish(.get(url, etag))
            completion(JSONResult.success(.successful(json: [:])))
        }
        return sub
    }

    func getJsonAsObject<T>(url: URLConvertible, etag: String?, completion: @escaping (ObjectResult<T>) -> Void) -> TealiumDisposable where T: Codable {
        let sub = TealiumSubscription { }
        delayBlock {
            guard !sub.isDisposed else {
                completion(.failure(.cancelled))
                return
            }
            self._requests.publish(.get(url, etag))
            switch self.codableResult {
            case let .success(response):
                if let object = response.object as? T {
                    completion(.success(.successful(object: object)))
                } else {
                    completion(.failure(.unknown(MockError.failedToConvertToExpectedResultType)))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
        return sub
    }

    func post(url: URLConvertible, body: [String: Any], completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        let sub = TealiumSubscription { }
        delayBlock {
            guard !sub.isDisposed else {
                completion(.failure(.cancelled))
                return
            }
            self._requests.publish(.post(url, body))
            completion(self.result)
        }
        return sub
    }
}
