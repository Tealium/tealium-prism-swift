//
//  RequestBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A builder for `URLRequest`s to send through a `NetworkClient`.
 *
 * Use the `makePOST(url:json:)` / `makeGET(url:etag:)` factories to start a request, chain the
 * builder methods to configure it, and hand the builder to `NetworkClient.sendRequest(_:completion:)`
 * (which builds it for you). Request bodies are **uncompressed by default**; opt into gzip
 * compression with `gzip()`.
 */
public class RequestBuilder {
    /// HTTP methods supported by RequestBuilder.
    public enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case head = "HEAD"
        case options = "OPTIONS"
    }

    enum HeaderKeys {
        static let ifNoneMatch = "If-None-Match"
        static let contentType = "Content-Type"
        static let contentEncoding = "Content-Encoding"
    }

    private let url: URLConvertible
    private let method: HTTPMethod?
    private var body: DataObject?
    private var shouldGzip = false
    private var headers: [String: String] = [:]

    /**
     * Creates a builder for a custom HTTP request.
     *
     * For common GET and POST requests, consider using the `makeGET(url:etag:)` or
     * `makePOST(url:json:)` factory methods instead.
     *
     * - Parameters:
     *    - url: the destination URL or URL-convertible value.
     *    - method: the HTTP method (defaults to GET if nil).
     */
    public init(url: URLConvertible, method: HTTPMethod? = nil) {
        self.url = url
        self.method = method
    }

    /**
     * Creates a builder for a POST request with a JSON body.
     *
     * The body is **uncompressed** by default. Call `gzip()` on the returned builder to opt into
     * gzip compression (e.g. for endpoints that support it).
     *
     * - Parameters:
     *    - url: the `URLConvertible` used to build the destination `URL`.
     *    - json: the `DataObject` to send as a JSON body.
     * - Returns: a `RequestBuilder` configured for the POST request.
     */
    public static func makePOST(url: URLConvertible, json: DataObject) -> RequestBuilder {
        RequestBuilder(url: url, method: .post)
            .jsonBody(json)
    }

    /**
     * Creates a builder for a GET request.
     *
     * - Parameters:
     *    - url: the `URLConvertible` used to build the destination `URL`.
     *    - etag: an optional etag added as the `If-None-Match` header to avoid fetching a cached resource.
     * - Returns: a `RequestBuilder` configured for the GET request.
     */
    public static func makeGET(url: URLConvertible, etag: String? = nil) -> RequestBuilder {
        RequestBuilder(url: url, method: .get)
            .etag(etag)
    }

    /**
     * Enables or disables gzip compression of the request body.
     *
     * When enabled, `build()` compresses the body and sets the `Content-Encoding: gzip` header.
     * If compression fails, the request falls back to the uncompressed body without that header.
     *
     * - Parameter shouldGzip: `true` to compress the body (the default), `false` to leave it uncompressed.
     * - Returns: this builder, to allow chaining.
     */
    @discardableResult
    public func gzip(_ shouldGzip: Bool = true) -> RequestBuilder {
        self.shouldGzip = shouldGzip
        return self
    }

    /**
     * Adds the given headers to the request.
     *
     * - Parameter additionalHeaders: a dictionary of header fields and values to add, if any.
     * - Returns: this builder, to allow chaining.
     */
    @discardableResult
    public func additionalHeaders(_ additionalHeaders: [String: String]?) -> RequestBuilder {
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                header(value, forField: key)
            }
        }
        return self
    }

    /**
     * Sets the value for a single header field.
     *
     * - Parameters:
     *    - value: the value to set, or `nil` to remove the header.
     *    - field: the header field name.
     * - Returns: this builder, to allow chaining.
     */
    @discardableResult
    public func header(_ value: String?, forField field: String) -> Self {
        headers[field] = value
        return self
    }

    func etag(_ etag: String?) -> Self {
        header(etag, forField: HeaderKeys.ifNoneMatch)
    }

    @discardableResult
    private func jsonBody(_ body: DataObject?) -> Self {
        header("application/json", forField: HeaderKeys.contentType)
        self.body = body
        return self
    }

    func encodeBody() throws -> Data? {
        guard let body else { return nil }
        return try Tealium.jsonEncoder.encode(AnyCodable(body.asDictionary()))
    }

    private func compressBody() throws -> (data: Data?, gzipped: Bool) {
        guard let data = try encodeBody() else { return (nil, false) }
        do {
            return (try data.gzipped(level: .bestCompression), true)
        } catch {
            return (data, false)
        }
    }

    /**
     * Builds the configured `URLRequest`.
     *
     * - Returns: the built `URLRequest`.
     * - Throws: an error if the URL is malformed or the body cannot be encoded.
     */
    public func build() throws -> URLRequest {
        var request = try URLRequest(url: url.asUrl())
        request.httpMethod = method?.rawValue
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        if shouldGzip {
            let compressed = try compressBody()
            request.httpBody = compressed.data
            if compressed.gzipped {
                request.setValue("gzip", forHTTPHeaderField: HeaderKeys.contentEncoding)
            }
        } else {
            request.httpBody = try encodeBody()
        }
        return request
    }
}

extension RequestBuilder: CustomStringConvertible {
    public var description: String {
        var desc = "\(method?.rawValue ?? "GET"): \(url)\nHeaders: \(headers)"
        if let body {
            desc += "\nBody: \(body)"
        }
        return desc
    }
}
