//
//  RequestBuilderTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class RequestBuilderTests: XCTestCase {

    let url = "https://www.tealium.com"

    func test_build_creates_a_URLRequest_with_provided_parameters() {
        let data = Data()
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder(url: url, method: .post)
            .body(data)
            .etag("Some Etag")
            .header("Some header", forField: "HEADER_KEY")
            .build())
        XCTAssertEqual(urlRequest?.url, try? url.asUrl())
        XCTAssertEqual(urlRequest?.httpMethod, "POST")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "ETAG"), "Some Etag")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "HEADER_KEY"), "Some header")
    }

    func test_gzip_zips_body_and_sets_headers() {
        let jsonDictionary = ["key": "value"]
        let urlRequest = XCTAssertNoThrowReturn(try RequestBuilder(url: url, method: .post)
            .gzip(json: jsonDictionary).build())
        XCTAssertEqual(urlRequest?.httpBody?.isGzipped, true, "Data is not compressed")
        XCTAssertEqual(urlRequest?.httpBody, try? JSONSerialization.data(withJSONObject: jsonDictionary).gzipped(level: .bestCompression))
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(urlRequest?.value(forHTTPHeaderField: "Content-Encoding"), "gzip")
    }
}
