//
//  NetworkHelperProtocol.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol NetworkHelperProtocol {
    typealias JSONResult = Result<[String: Any], NetworkError>
    typealias CodableResult<T> = Result<T, NetworkError>

    /**
     * Just sends a GET request to the `NetworkClient`
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - etag: the etag to be added in order to avoid fetching a cached resource
     *    - completion: the block that is executed when the request is completed with the `NetworkResult`
     *
     * - Returns: the `TealiumDisposableProtocol` to cancel the in flight operation.
     */
    func get(url: URLConvertible, etag: String?, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable
    /**
     * Sends a GET request to the `NetworkClient` and tries to convert the result the returned JSON into a  `[String: Any]`.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - etag: the etag to be added in order to avoid fetching a cached resource
     *    - completion: the block that is executed when the request is completed with the `JSONResult`
     *
     * - Returns: the `TealiumDisposableProtocol` to cancel the in flight operation.
     */
    func getJsonAsDictionary(url: URLConvertible, etag: String?, completion: @escaping (JSONResult) -> Void) -> TealiumDisposable
    /**
     * Sends a GET request to the `NetworkClient` and tries to convert the result into a Codable model.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - etag: the etag to be added in order to avoid fetching a cached resource
     *    - completion: the block that is executed when the request is completed with the `CodableResult`
     *
     * - Returns: the `TealiumDisposableProtocol` to cancel the in flight operation.
     */
    func getJsonAsObject<T: Codable>(url: URLConvertible, etag: String?, completion: @escaping (CodableResult<T>) -> Void) -> TealiumDisposable
    /**
     * Sends a POST request to the `NetworkClient`with a gzipped JSON body.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - body: the `Dictionary` to be sent as a gzipped JSON data
     *    - completion: the block that is executed when the request is completed with the `NetworkResult`
     *
     * - Returns: the `TealiumDisposableProtocol` to cancel the in flight operation.
     */
    func post(url: URLConvertible, body: [String: Any], completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable
}

public extension NetworkHelperProtocol {
    /**
     * Just sends a GET request to the `NetworkClient`. Same as using the `get` method with nil as the `etag` parameter.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - completion: the block that is executed when the request is completed with the `NetworkResult`
     *
     * - Returns: the `TealiumDisposableProtocol` to cancel the in flight operation.
     */
    func get(url: URLConvertible, completion: @escaping (NetworkResult) -> Void) -> TealiumDisposable {
        get(url: url, etag: nil, completion: completion)
    }
    /**
     * Sends a GET request to the `NetworkClient` and tries to convert the result the returned JSON into a  `[String: Any]`. Same as using the `get` method with nil as the `etag` parameter.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - etag: the etag to be added in order to avoid fetching a cached resource
     *    - completion: the block that is executed when the request is completed with the `JSONResult`
     *
     * - Returns: the `TealiumDisposableProtocol` to cancel the in flight operation.
     */
    func getJsonAsDictionary(url: URLConvertible, completion: @escaping (JSONResult) -> Void) -> TealiumDisposable {
        getJsonAsDictionary(url: url, etag: nil, completion: completion)
    }
    /**
     * Sends a GET request to the `NetworkClient` and tries to convert the result into a Codable model. Same as using the `get` method with nil as the `etag` parameter.
     *
     * - Parameters:
     *    - url: the `URLConvertible` instance to build the `URL` to send
     *    - completion: the block that is executed when the request is completed with the `CodableResult`
     *
     * - Returns: the `TealiumDisposableProtocol` to cancel the in flight operation.
     */
    func getJsonAsObject<T: Codable>(url: URLConvertible, completion: @escaping (CodableResult<T>) -> Void) -> TealiumDisposable {
        getJsonAsObject(url: url, etag: nil, completion: completion)
    }
}
