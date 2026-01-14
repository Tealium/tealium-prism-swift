//
//  RequestBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A utility class to easily build URLRequests
class RequestBuilder {
    enum HeaderKeys {
        static let ifNoneMatch = "If-None-Match"
        static let contentType = "Content-Type"
        static let contentEncoding = "Content-Encoding"
    }
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
    private let url: URLConvertible
    private let method: HTTPMethod?
    private var body: DataObject?
    private var shouldGzip = false
    private var headers: [String: String] = [:]
    init(url: URLConvertible, method: HTTPMethod? = nil) {
        self.url = url
        self.method = method
    }

    static func makePOST(url: URLConvertible, gzippedJson json: DataObject) -> RequestBuilder {
        RequestBuilder(url: url, method: .post)
            .gzippedBody(json)
    }

    static func makeGET(url: URLConvertible, etag: String?) -> RequestBuilder {
        RequestBuilder(url: url, method: .get)
            .etag(etag)
    }

    func additionalHeaders(_ additionalHeaders: [String: String]?) -> RequestBuilder {
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                header(value, forField: key)
            }
        }
        return self
    }

    @discardableResult
    func header(_ value: String?, forField field: String) -> Self {
        headers[field] = value
        return self
    }

    func etag(_ etag: String?) -> Self {
        header(etag, forField: HeaderKeys.ifNoneMatch)
    }

    @discardableResult
    func uncompressedBody(_ body: DataObject?) -> Self {
        header("application/json", forField: HeaderKeys.contentType)
        self.body = body
        shouldGzip = false
        return self
    }

    func gzippedBody(_ json: DataObject) -> Self {
        header("gzip", forField: HeaderKeys.contentEncoding)
        defer { shouldGzip = true }
        return uncompressedBody(json)
    }

    func encodeBody() throws -> Data? {
        guard let body else { return nil }
        return try Tealium.jsonEncoder.encode(AnyCodable(body.asDictionary()))
    }

    private func compressBody() throws -> Data? {
        guard let data = try encodeBody() else { return nil }
        do {
            let gzippedData = try data.gzipped(level: .bestCompression)
            return gzippedData
        } catch {
            headers.removeValue(forKey: HeaderKeys.contentEncoding)
            return data
        }
    }

    func build() throws -> URLRequest {
        var request = try URLRequest(url: url.asUrl())
        request.httpBody = shouldGzip ? try compressBody() : try encodeBody()
        request.httpMethod = method?.rawValue
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        return request
    }
}

extension RequestBuilder: CustomStringConvertible {
    var description: String {
        var desc = "\(method?.rawValue ?? "GET"): \(url)\nHeaders: \(headers)"
        if let body {
            desc += "\nBody: \(body)"
        }
        return desc
    }
}
