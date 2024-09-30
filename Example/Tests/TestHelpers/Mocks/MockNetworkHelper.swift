//
//  MockNetworkHelper.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 15/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

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
    var codableResult: ObjectResult<Any> = ObjectResult.success(.successful(object: ()))
    var delay: Int?
    var queue = DispatchQueue.main
    enum Requests {
        case get(URLConvertible, String?)
        case post(URLConvertible, DataObject)
    }

    @ToAnyObservable(ReplaySubject(cacheSize: 10))
    var requests: Observable<Requests>

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

    func get(url: URLConvertible, etag: String?, completion: @escaping (NetworkResult) -> Void) -> Disposable {
        let sub = Subscription { }
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

    func getJsonAsObject<T>(url: URLConvertible, etag: String?, completion: @escaping (ObjectResult<T>) -> Void) -> Disposable where T: Codable {
        let sub = Subscription { }
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

    func post(url: URLConvertible, body: DataObject, completion: @escaping (NetworkResult) -> Void) -> Disposable {
        let sub = Subscription { }
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
