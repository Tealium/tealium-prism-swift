//
//  URLTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class URLTests: XCTestCase {

    func test_appendingQueryItems_returns_url_with_query_items() throws {
        let url = try "https://www.tealium.com".asUrl()
        let result = url.appendingQueryItems([
            URLQueryItem(name: "key1", value: "value1"),
            URLQueryItem(name: "key2", value: nil),
        ])
        XCTAssertEqual(result.absoluteString, "https://www.tealium.com?key1=value1&key2")
    }

    func test_appendingQueryItems_returns_same_url_with_empty_params() throws {
        let url = try "https://www.tealium.com".asUrl()
        let result = url.appendingQueryItems([])
        XCTAssertEqual(result, url)
    }

}
