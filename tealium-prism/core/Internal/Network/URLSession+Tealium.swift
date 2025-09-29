//
//  URLSession+Tealium.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

extension URLSessionDataTask: Disposable {
    public var isDisposed: Bool {
        self.state == .canceling
    }

    public func dispose() {
        cancel()
    }
}

extension URLSession {

    /**
     * Sends a `URLRequest` with a `URLSessionDataTask` and transforms the response into a `NetworkResult`.
     *
     * Note:
     * Non 2xx status responses are automatically converted to a `non200Status` error.
     *
     * - Parameters:
     *    - request: the `URLRequest` to be sent
     *    - completion: the completion block called once the request completes
     *
     *  - Returns: the `URLSessionDataTask` that was just created and resumed
     */
    func send(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> URLSessionDataTask {
        let task = dataTask(with: request) { data, response, error in
            if let error = error {
                if let urlError = error as? URLError {
                    if urlError.code == .cancelled {
                        completion(.failure(.cancelled))
                    } else {
                        completion(.failure(.urlError(urlError)))
                    }
                } else {
                    completion(.failure(.unknown(error)))
                }
                return
            }

            guard let response = response as? HTTPURLResponse, let data = data else {
                completion(.failure(.unknown(nil)))
                return
            }

            guard (200..<300).contains(response.statusCode) else {
                completion(.failure(.non200Status(response.statusCode)))
                return
            }

            completion(.success(NetworkResponse(data: data, urlResponse: response)))
        }
        task.resume()
        return task
    }

}
