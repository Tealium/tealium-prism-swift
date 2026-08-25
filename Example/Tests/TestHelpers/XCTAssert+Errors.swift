//
//  XCTAssert+Errors.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 01/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

enum TestError: Error, Equatable {
    case fileNotFound(named: String)
    case unknown
}

func XCTAssertTestErrorEquals(
    _ testError: Error,
    _ other: TestError,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let testError = testError as? TestError else {
        XCTFail("Underlying error is not a TestError \(testError)", file: file, line: line)
        return
    }
    XCTAssertEqual(testError, other, file: file, line: line)
}

func XCTAssertNetworkError(
    _ networkError: NetworkError,
    equalsURLErrorWith underlyingError: Error?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let underlyingError = underlyingError as? URLError else {
        XCTFail("Underlying error is not an URLError \(underlyingError as Any)", file: file, line: line)
        return
    }

    guard case let .urlError(urlError) = networkError.type else {
        XCTFail("NetworkError is not an URLError \(networkError.type)", file: file, line: line)
        return
    }

    XCTAssertEqual(urlError.code, underlyingError.code, file: file, line: line)
}

func XCTAssertNetworkError(
    _ networkError: NetworkErrorType,
    equalsNon200StatusErrorWith code: Int,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard case let .non200Status(actual, _) = networkError else {
        XCTFail("NetworkError is not an non200Status \(networkError)", file: file, line: line)
        return
    }

    XCTAssertEqual(actual, code, file: file, line: line)
}

enum NetworkErrorSimplifiedType: String, Error {
    case non200Status
    case cancelled
    case urlError
    case unknown
}

func XCTAssertNetworkError(
    _ networkError: Error,
    is type: NetworkErrorSimplifiedType,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let networkError = networkError as? NetworkError else {
        XCTFail("Expected NetworkError but got \(networkError)", file: file, line: line)
        return
    }
    XCTAssertNetworkErrorType(networkError.type, is: type, file: file, line: line)
}

func XCTAssertNetworkErrorType(
    _ networkError: Error,
    is type: NetworkErrorSimplifiedType,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let networkError = networkError as? NetworkErrorType else {
        XCTFail("Expected NetworkErrorType but got \(networkError)", file: file, line: line)
        return
    }
    switch (networkError, type) {
    case (.non200Status, .non200Status),
        (.cancelled, .cancelled),
        (.urlError, .urlError),
        (.unknown, .unknown): break
    default:
        XCTFail("\(networkError) is not of type \(type.rawValue)", file: file, line: line)
    }
}

func XCTAssertThrows<T, E: Error>(_ expression: @autoclosure () throws(E) -> T,
                                  _ message: @autoclosure () -> String = "",
                                  file: StaticString = #filePath,
                                  line: UInt = #line,
                                  _ errorHandler: (_ error: E) -> Void = { _ in }) {
    do {
        _ = try expression()
        XCTFail("Expression expected to throw but succeeded instead", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
