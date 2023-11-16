//
//  MockNetworkHelper.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 15/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockNetworkHelper: NetworkHelperProtocol {
    enum MockError: Error {
        case failedToConvertToExpectedResultType
    }
    var result: NetworkResult = NetworkResult.success(.successful())
    var jsonResult: JSONResult = JSONResult.success([:])
    var codableResult: CodableResult<Any> = CodableResult.success(())
    enum Requests {
        case get(URLConvertible, String?)
        case post(URLConvertible, [String: Any])
    }

    @ToAnyObservable(TealiumReplaySubject(cacheSize: 10))
    var requests: TealiumObservable<Requests>

    func get(url: URLConvertible, etag: String?, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        _requests.publish(.get(url, etag))
        completion(result)
        return TealiumSubscription { }
    }

    func getJsonAsDictionary(url: URLConvertible, etag: String?, completion: @escaping (JSONResult) -> Void) -> TealiumDisposable {
        _requests.publish(.get(url, etag))
        completion(JSONResult.success([:]))
        return TealiumSubscription { }
    }

    func getJsonAsObject<T>(url: URLConvertible, etag: String?, completion: @escaping (CodableResult<T>) -> Void) -> TealiumDisposable where T: Codable {
        _requests.publish(.get(url, etag))
        switch codableResult {
        case let .success(object):
            if let object = object as? T {
                completion(.success(object))
            } else {
                completion(.failure(.unknown(MockError.failedToConvertToExpectedResultType)))
            }
        case let .failure(error):
            completion(.failure(error))
        }
        return TealiumSubscription { }
    }

    func post(url: URLConvertible, body: [String: Any], completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        _requests.publish(.post(url, body))
        completion(result)
        return TealiumSubscription { }
    }
}
