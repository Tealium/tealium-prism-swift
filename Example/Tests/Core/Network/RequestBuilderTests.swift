//
//  RequestBuilderTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class RequestBuilderTests: XCTestCase {

    let url = "https://www.tealium.com"

    func test_build_creates_a_URLRequest_with_provided_parameters() {
        let data = DataObject()
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder.makePOST(url: url, json: data)
            .etag("Some Etag")
            .header("Some header", forField: "HEADER_KEY")
            .build())
        XCTAssertEqual(urlRequest?.url, try? url.asUrl())
        XCTAssertEqual(urlRequest?.httpMethod, "POST")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "If-None-Match"), "Some Etag")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "HEADER_KEY"), "Some header")
    }

    func test_makePOST_leaves_body_uncompressed_by_default() {
        let dataObject: DataObject = ["key": "value"]
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder.makePOST(url: url, json: dataObject).build())
        XCTAssertNotEqual(urlRequest?.httpBody?.isGzipped, true, "Data should not be compressed")
        XCTAssertEqual(urlRequest?.httpBody, try? Tealium.jsonEncoder.encode(AnyCodable(dataObject.asDictionary())))
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNil(urlRequest?.value(forHTTPHeaderField: "Content-Encoding"))
    }

    func test_gzip_zips_body_and_sets_headers() {
        let dataObject: DataObject = ["key": "value"]
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder.makePOST(url: url, json: dataObject)
            .gzip().build())
        XCTAssertEqual(urlRequest?.httpBody?.isGzipped, true, "Data is not compressed")
        XCTAssertEqual(urlRequest?.httpBody, try? Tealium.jsonEncoder.encode(AnyCodable(dataObject.asDictionary())).gzipped(level: .bestCompression))
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Content-Encoding"), "gzip")
    }

    func test_encodeBody_converts_invalid_numbers_to_strings() {
        let dataObject: DataObject = ["nan": Double.nan, "infinity": Double.infinity]
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder.makePOST(url: url, json: dataObject)
            .gzip().build())
        XCTAssertEqual(urlRequest?.httpBody?.isGzipped, true, "Data is not compressed")
        guard let deserializedBody = urlRequest?.httpBody?.gunzippedJSON() else { return }
        XCTAssertEqual(deserializedBody["nan"] as? String, "NaN")
        XCTAssertEqual(deserializedBody["infinity"] as? String, "Infinity")
    }

    func test_makeGET_creates_a_GET_request_with_no_body() {
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder.makeGET(url: url).build())
        XCTAssertEqual(urlRequest?.url, try? url.asUrl())
        XCTAssertEqual(urlRequest?.httpMethod, "GET")
        XCTAssertNil(urlRequest?.httpBody)
        XCTAssertNil(urlRequest?.value(forHTTPHeaderField: "Content-Type"))
    }

    func test_makeGET_sets_etag_header_when_provided() {
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder.makeGET(url: url, etag: "abc123").build())
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "If-None-Match"), "abc123")
    }

    func test_makeGET_omits_etag_header_when_nil() {
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder.makeGET(url: url, etag: nil).build())
        XCTAssertNil(urlRequest?.value(forHTTPHeaderField: "If-None-Match"))
    }

    func test_gzip_false_leaves_body_uncompressed() {
        let dataObject: DataObject = ["key": "value"]
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder.makePOST(url: url, json: dataObject)
            .gzip().gzip(false).build())
        XCTAssertNotEqual(urlRequest?.httpBody?.isGzipped, true)
        XCTAssertNil(urlRequest?.value(forHTTPHeaderField: "Content-Encoding"))
    }

    func test_header_nil_value_removes_header() {
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder.makePOST(url: url, json: DataObject())
            .header("initial", forField: "X-Custom")
            .header(nil, forField: "X-Custom")
            .build())
        XCTAssertNil(urlRequest?.value(forHTTPHeaderField: "X-Custom"))
    }

    func test_build_throws_on_malformed_url() {
        XCTAssertThrowsError(try RequestBuilder(url: "not a valid url ://", method: .get).build())
    }

    func test_additionalHeaders_adds_additionalHeaders() {
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder(url: url, method: .post)
            .additionalHeaders(["header1": "value1", "header2": "value2"])
            .build())
        XCTAssertEqual(urlRequest?.url, try? url.asUrl())
        XCTAssertEqual(urlRequest?.httpMethod, "POST")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "header1"), "value1")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "header2"), "value2")
    }
}
