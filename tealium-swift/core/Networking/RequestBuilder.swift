//
//  RequestBuilder.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A utility class to easily build URLRequests
class RequestBuilder {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
    private let url: URLConvertible
    private let method: HTTPMethod?
    private var body: Data?
    private var headers: [String: String] = [:]
    init(url: URLConvertible, method: HTTPMethod? = nil) {
        self.url = url
        self.method = method
    }

    static func makePOST(url: URLConvertible, gzippedJson json: [String: Any]) throws -> RequestBuilder {
        try RequestBuilder(url: url, method: .post)
            .gzip(json: json)
    }

    static func makeGET(url: URLConvertible, etag: String?) -> RequestBuilder {
        RequestBuilder(url: url, method: .get)
            .etag(etag)
    }

    @discardableResult
    func header(_ value: String?, forField field: String) -> Self {
        headers[field] = value
        return self
    }

    func etag(_ etag: String?) -> Self {
        header(etag, forField: "ETAG")
    }

    @discardableResult
    func body(_ body: Data?) -> Self {
        self.body = body
        return self
    }

    func gzip(json: [String: Any]) throws -> Self {
        header("application/json", forField: "Content-Type")
        guard JSONSerialization.isValidJSONObject(json) else {
            throw ParsingError.nonConvertibleToJSONObject(json)
        }
        let data = try JSONSerialization.data(withJSONObject: json)
        if let gzippedData = try? data.gzipped(level: .bestCompression) {
            header("gzip", forField: "Content-Encoding")
            body(gzippedData)
        } else {
            body(data)
        }
        return self
    }

    func build() throws -> URLRequest {
        var request = URLRequest(url: try url.asUrl())
        request.httpBody = body
        request.httpMethod = method?.rawValue
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        return request
    }
}
