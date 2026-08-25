//
//  NetworkResultTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/08/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class NetworkResultTests: XCTestCase {

    func test_shortDescription_contains_error_shortDescription_for_failure_case() throws {
        let url = try "someUrl".asUrl()
        let error = NetworkError(type: .non200Status(400, Data("Some Body".utf8)),
                                 urlResponse: HTTPURLResponse(url: url,
                                                              statusCode: 400,
                                                              httpVersion: nil,
                                                              headerFields: nil))
        let result = NetworkResult.failure(error)
        XCTAssertTrue(result.shortDescription().contains(error.shortDescription()))
    }

    func test_shortDescription_contains_not_modified_for_304() throws {
        let url = try "someUrl".asUrl()
        let error = NetworkError(type: .non200Status(304, Data("Some Body".utf8)),
                                 urlResponse: HTTPURLResponse(url: url,
                                                              statusCode: 304,
                                                              httpVersion: nil,
                                                              headerFields: nil))
        let result = NetworkResult.failure(error)
        XCTAssertTrue(result.shortDescription().contains("not modified"))
    }

    func test_shortDescription_contains_response_status_code_for_success_case() {
        let response = NetworkResponse(data: Data("Some Body".utf8),
                                       urlResponse: .successful())
        let result = NetworkResult.success(response)
        XCTAssertTrue(result.shortDescription().contains("200"))
    }

    func test_longDescription_contains_error_longDescription_for_failure_case() throws {
        let url = try "someUrl".asUrl()
        let error = NetworkError(type: .non200Status(400, Data("Some Body".utf8)),
                                 urlResponse: HTTPURLResponse(url: url,
                                                              statusCode: 400,
                                                              httpVersion: nil,
                                                              headerFields: nil))
        let result = NetworkResult.failure(error)
        XCTAssertTrue(result.longDescription().contains(error.longDescription()))
    }

    func test_longDescription_contains_response_status_code_for_success_case() {
        let response = NetworkResponse(data: Data("Some Body".utf8),
                                       urlResponse: .successful())
        let result = NetworkResult.success(response)
        XCTAssertTrue(result.longDescription().contains("200"))
    }

    func test_longDescription_contains_empty_body() {
        let response = NetworkResponse(data: Data(), urlResponse: .successful())
        let result = NetworkResult.success(response)
        XCTAssertTrue(result.longDescription().contains("Empty body"))
    }

    func test_logLevel_is_debug_for_success() {
        let response = NetworkResponse(data: Data(), urlResponse: .successful())
        let result = NetworkResult.success(response)
        XCTAssertEqual(result.logLevel(), .debug)
    }

    func test_logLevel_is_debug_for_304() {
        let result = NetworkResult.failure(NetworkError(type: .non200Status(304, nil)))
        XCTAssertEqual(result.logLevel(), .debug)
    }

    func test_logLevel_is_error_for_error() {
        let result = NetworkResult.failure(NetworkError(type: .non200Status(400, nil)))
        XCTAssertEqual(result.logLevel(), .error)
    }

    func test_urlResponse_is_not_nil_for_success() {
        let response = NetworkResponse(data: Data(), urlResponse: .successful())
        let result = NetworkResult.success(response)
        XCTAssertNotNil(result.urlResponse)
    }

    func test_urlResponse_is_not_nil_for_error_with_response() {
        let result = NetworkResult.failure(NetworkError(type: .non200Status(304, nil),
                                                        urlResponse: .successful()))
        XCTAssertNotNil(result.urlResponse)
    }

    func test_urlResponse_is_nil_for_error_without_response() {
        let result = NetworkResult.failure(NetworkError(type: .non200Status(304, nil)))
        XCTAssertNil(result.urlResponse)
    }

}
