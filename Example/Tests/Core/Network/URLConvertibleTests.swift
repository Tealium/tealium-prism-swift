//
//  URLConvertibleTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class URLConvertibleTests: XCTestCase {

    let urlString = "https://www.tealium.com"

    func test_string_converts_to_url() {
        let url = XCTAssertNoThrowReturn(try urlString.asUrl())
        XCTAssertEqual(url?.absoluteString, urlString)
    }

    func test_empty_string_throws_a_conversion_error() {
        let emptyString = ""
        XCTAssertThrows(try emptyString.asUrl()) { (error: ConversionError) in
            guard case let .invalidUrl(url) = error else {
                XCTFail("ConversionError should be invalid URL")
                return
            }
            XCTAssertEqual(emptyString, url as? String)
        }
    }

    func test_URLComponents_converts_to_url() {
        let urlComponents = URLComponents(string: urlString)
        guard let url = XCTAssertNoThrowReturn(try urlComponents?.asUrl()) as? URL else {
            XCTFail("Failed to return URL from \(urlString)")
            return
        }
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: true), urlComponents)
    }

    func test_malformed_URLComponents_throws_a_conversion_error() {
        var urlComponents = URLComponents()
        urlComponents.path = "//someWrongPath"
        XCTAssertThrows(try urlComponents.asUrl()) { (error: ConversionError) in
            guard case let .invalidUrl(url) = error else {
                XCTFail("ConversionError should be invalid URL")
                return
            }
            XCTAssertEqual(urlComponents, url as? URLComponents)
        }
    }

    func test_URL_converts_to_itself() throws {
        let url = try urlString.asUrl()
        let urlResult = XCTAssertNoThrowReturn(try url.asUrl())
        XCTAssertEqual(url, urlResult)
    }
}
