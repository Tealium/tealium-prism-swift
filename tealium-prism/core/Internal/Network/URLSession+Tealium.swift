//
//  URLSession+Tealium.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

extension URLSession {

    /**
     * Sends a `URLRequest` with a `URLSessionDataTask` and transforms the response into a `NetworkResult`.
     *
     * - Note: Non 2xx status responses are automatically converted to a `non200Status` error.
     * - Note: This method is only intended to work with HTTP and HTTPS schemes,
     * will complete with an unknown error if used with another scheme.
     *
     * - Parameters:
     *    - request: the `URLRequest` to be sent
     *    - completion: the completion block called once the request completes
     *
     *  - Returns: the `URLSessionDataTask` that was just created and resumed
     */
    func send(_ request: URLRequest, completion: @escaping (NetworkResult) -> Void) -> URLSessionDataTask {
        let interval = TealiumSignpostInterval(signposter: .httpClient, name: "DataTask").begin(request.url?.absoluteString ?? "")
        let task = dataTask(with: request) { data, response, error in
            interval.end()
            do throws(NetworkError) {
                completion(.success(try URLSession.makeResponse(data: data, response: response, error: error)))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
        return task
    }

    /**
     * Maps the raw `URLSessionDataTask` completion arguments into a `NetworkResponse`,
     * throwing a `NetworkError` when the request did not complete successfully.
     *
     * A non 2xx status is reported in preference to a transport error when both are delivered together,
     * and the received `HTTPURLResponse` (if any) is always attached to the thrown `NetworkError`.
     *
     * - Parameters:
     *    - data: the body data returned by the data task, if any
     *    - response: the `URLResponse` returned by the data task, if any
     *    - error: the error returned by the data task, if any
     *  - Returns: the `NetworkResponse` representing the successful outcome of the request
     *  - Throws: a `NetworkError` describing why the request failed
     */
    static func makeResponse(data: Data?, response: URLResponse?, error: Error?) throws(NetworkError) -> NetworkResponse {
        let response = response as? HTTPURLResponse
        do throws(NetworkErrorType) {
            if let response {
                guard (200..<300).contains(response.statusCode) else {
                    throw NetworkErrorType.non200Status(response.statusCode, data)
                }
            }
            if let error = error {
                guard let urlError = error as? URLError else {
                    throw NetworkErrorType.unknown(error)
                }
                if urlError.code == .cancelled {
                    throw NetworkErrorType.cancelled
                } else {
                    throw NetworkErrorType.urlError(urlError)
                }
            }
            guard let response else {
                // This only happens if the URLRequest is for a custom schema and the URLSession supports that schema, not our case.
                throw NetworkErrorType.unknown(nil)
            }
            guard let data else {
                // This never happens, as test `test_send_surfaces_empty_data_when_protocol_body_is_nil` proves
                throw NetworkErrorType.unknown(nil)
            }
            return NetworkResponse(data: data, urlResponse: response)
        } catch {
            throw NetworkError(type: error, urlResponse: response)
        }
    }
}
