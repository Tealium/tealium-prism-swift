//
//  XCTAssert+Errors.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 01/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

func XCTAssertNetworkError(
    _ networkError: NetworkError,
    equalsURLErrorWith underlyingError: Error?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let underlyingError = underlyingError as? URLError else {
        XCTFail("Underlying error is not an URLError")
        return
    }
    XCTAssertEqual(networkError, .urlError(underlyingError))
}
