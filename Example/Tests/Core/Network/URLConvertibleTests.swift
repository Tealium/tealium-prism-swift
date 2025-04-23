//
//  URLConvertibleTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class URLConvertibleTests: XCTestCase {

    let urlString = "https://www.tealium.com"

    func test_string_converts_to_url() {
        let url = XCTAssertNoThrowReturn(try urlString.asUrl())
        XCTAssertEqual(url?.absoluteString, urlString)
    }

    func test_empty_string_throws_an_error() {
        let emptyString = ""
        XCTAssertThrowsError(try emptyString.asUrl()) { error in
            let parsingError = error as? ParsingError
            XCTAssertNotNil(parsingError, "Error should be a parsing error")
            guard case let .invalidUrl(url) = parsingError else {
                XCTFail("ParsingError should be invalid URL")
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

    func test_malformed_URLComponents_throws_an_error() {
        var urlComponents = URLComponents()
        urlComponents.path = "//someWrongPath"
        XCTAssertThrowsError(try urlComponents.asUrl()) { error in
            let parsingError = error as? ParsingError
            XCTAssertNotNil(parsingError, "Error should be a parsing error")
            guard case let .invalidUrl(url) = parsingError else {
                XCTFail("ParsingError should be invalid URL")
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
