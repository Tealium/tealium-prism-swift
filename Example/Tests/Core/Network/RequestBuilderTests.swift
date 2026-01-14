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
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder(url: url, method: .post)
            .uncompressedBody(data)
            .etag("Some Etag")
            .header("Some header", forField: "HEADER_KEY")
            .build())
        XCTAssertEqual(urlRequest?.url, try? url.asUrl())
        XCTAssertEqual(urlRequest?.httpMethod, "POST")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "If-None-Match"), "Some Etag")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "HEADER_KEY"), "Some header")
    }

    func test_gzip_zips_body_and_sets_headers() {
        let dataObject: DataObject = ["key": "value"]
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder(url: url, method: .post)
            .gzippedBody(dataObject).build())
        XCTAssertEqual(urlRequest?.httpBody?.isGzipped, true, "Data is not compressed")
        XCTAssertEqual(urlRequest?.httpBody, try? Tealium.jsonEncoder.encode(AnyCodable(dataObject.asDictionary())).gzipped(level: .bestCompression))
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Content-Encoding"), "gzip")
    }

    func test_gzip_converts_invalid_numbers_to_strings() {
        let dataObject: DataObject = ["nan": Double.nan, "infinity": Double.infinity]
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder(url: url, method: .post)
            .gzippedBody(dataObject).build())
        XCTAssertEqual(urlRequest?.httpBody?.isGzipped, true, "Data is not compressed")
        guard let body = try? urlRequest?.httpBody?.gunzipped(),
              let deserializedBody = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            XCTFail("Can't deserialize body")
            return
        }
        XCTAssertEqual(deserializedBody["nan"] as? String, "NaN")
        XCTAssertEqual(deserializedBody["infinity"] as? String, "Infinity")
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
