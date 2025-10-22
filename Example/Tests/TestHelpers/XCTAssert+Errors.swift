//
//  XCTAssert+Errors.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 01/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

func XCTAssertNetworkError(
    _ networkError: NetworkError,
    equalsURLErrorWith underlyingError: Error?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let underlyingError = underlyingError as? URLError else {
        XCTFail("Underlying error is not an URLError", file: file, line: line)
        return
    }
    XCTAssertEqual(networkError, .urlError(underlyingError))
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
