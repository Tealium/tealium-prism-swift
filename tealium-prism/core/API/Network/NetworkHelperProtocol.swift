//
//  NetworkHelperProtocol.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A response containing a decoded object and the HTTP response.
public struct ObjectResponse<T> {
    /// The decoded object from the response.
    public let object: T
    /// The HTTP URL response.
    public let urlResponse: HTTPURLResponse
}

/// A result type for object responses.
public typealias ObjectResult<T> = Result<ObjectResponse<T>, NetworkError>

/// Protocol defining methods for common network operations.
public protocol NetworkHelperProtocol {
    /**
     * Just sends a GET request to the `NetworkClient`
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - etag: the etag to be added in order to avoid fetching a cached resource
     *    - additionalHeaders: optional dictionary of additional headers to add to the request
     *    - completion: the block that is executed when the request is completed with the `NetworkResult`
     *
     * - Returns: the `Disposable` to cancel the in flight operation.
     */
    func get(url: URLConvertible,
             etag: String?,
             additionalHeaders: [String: String]?,
             completion: @escaping (NetworkResult) -> Void) -> Disposable

    /**
     * Sends a GET request to the `NetworkClient` and tries to convert the result into a Codable model.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - etag: the etag to be added in order to avoid fetching a cached resource
     *    - additionalHeaders: optional dictionary of additional headers to add to the request
     *    - completion: the block that is executed when the request is completed with the `CodableResult`
     *
     * - Returns: the `Disposable` to cancel the in flight operation.
     */
    func getJsonAsObject<T: Codable>(url: URLConvertible,
                                     etag: String?,
                                     additionalHeaders: [String: String]?,
                                     completion: @escaping (ObjectResult<T>) -> Void) -> Disposable

    /**
     * Sends a POST request to the `NetworkClient`with a gzipped JSON body.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - body: the `DataObject` to be sent as a gzipped JSON data
     *    - additionalHeaders: optional dictionary of additional headers to add to the request
     *    - completion: the block that is executed when the request is completed with the `NetworkResult`
     *
     * - Returns: the `Disposable` to cancel the in flight operation.
     */
    func post(url: URLConvertible,
              body: DataObject,
              additionalHeaders: [String: String]?,
              completion: @escaping (NetworkResult) -> Void) -> Disposable
}

/// Default implementations for NetworkHelperProtocol methods.
public extension NetworkHelperProtocol {
    /**
     * Just sends a GET request to the `NetworkClient`
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - additionalHeaders: optional dictionary of additional headers to add to the request
     *    - completion: the block that is executed when the request is completed with the `NetworkResult`
     *
     * - Returns: the `Disposable` to cancel the in flight operation.
     */
    func get(url: URLConvertible,
             additionalHeaders: [String: String]? = nil,
             completion: @escaping (NetworkResult) -> Void) -> Disposable {
        get(url: url, etag: nil, additionalHeaders: additionalHeaders, completion: completion)
    }

    /**
     * Sends a GET request to the `NetworkClient` and tries to convert the result the returned JSON into a  `DataObject`.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - etag: the etag to be added in order to avoid fetching a cached resource
     *    - additionalHeaders: optional dictionary of additional headers to add to the request
     *    - completion: the block that is executed when the request is completed with the `ObjectResult`
     *
     * - Returns: the `Disposable` to cancel the in flight operation.
     */
    func getJsonAsDataObject(url: URLConvertible,
                             etag: String? = nil,
                             additionalHeaders: [String: String]? = nil,
                             completion: @escaping (ObjectResult<DataObject>) -> Void) -> Disposable {
        getJsonAsObject(url: url,
                        etag: etag,
                        additionalHeaders: additionalHeaders,
                        completion: completion)
    }

    /**
     * Sends a GET request to the `NetworkClient` and tries to convert the result into a Codable model. Same as using the `get` method with nil as the `etag` parameter.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - etag: the etag to be added in order to avoid fetching a cached resource
     *    - additionalHeaders: optional dictionary of additional headers to add to the request
     *    - completion: the block that is executed when the request is completed with the `CodableResult`
     *
     * - Returns: the `Disposable` to cancel the in flight operation.
     */
    func getJsonAsObject<T: Codable>(url: URLConvertible,
                                     etag: String? = nil,
                                     additionalHeaders: [String: String]? = nil,
                                     completion: @escaping (ObjectResult<T>) -> Void) -> Disposable {
        get(url: url, etag: etag, additionalHeaders: additionalHeaders) { result in
            completion(result.flatMap { response in
                do {
                    return .success(ObjectResponse(object: try Tealium.jsonDecoder.decode(T.self, from: response.data),
                                                   urlResponse: response.urlResponse))
                } catch {
                    return .failure(.unknown(error))
                }
            })
        }
    }

    /**
     * Sends a POST request to the `NetworkClient`with a gzipped JSON body.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - body: the `DataObject` to be sent as a gzipped JSON data
     *    - completion: the block that is executed when the request is completed with the `NetworkResult`
     *
     * - Returns: the `Disposable` to cancel the in flight operation.
     */
    func post(url: URLConvertible,
              body: DataObject,
              completion: @escaping (NetworkResult) -> Void) -> Disposable {
        post(url: url, body: body, additionalHeaders: nil, completion: completion)
    }
}
