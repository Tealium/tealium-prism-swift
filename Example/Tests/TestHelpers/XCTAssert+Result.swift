//
//  XCTAssert+Result.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 15/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift
import XCTest

func XCTAssertResultIsSuccess<T, E>(
    _ result: Result<T, E>,
    withAsserts asserts: (T) -> Void = { _ in },
    file: StaticString = #filePath,
    line: UInt = #line
) {
    switch result {
    case .failure(let error):
        XCTFail("Expected to be a success but got a failure with \(error)", file: file, line: line)
    case .success(let resultValue):
        asserts(resultValue)
    }
}

func XCTAssertResultIsFailure<T, E>(
    _ result: Result<T, E>,
    withAsserts asserts: (E) -> Void = { _ in },
    file: StaticString = #filePath,
    line: UInt = #line
) {
    switch result {
    case .failure(let resultError):
        asserts(resultError)
    case .success(let value):
        XCTFail("Expected to be a failure but got a success with \(value)", file: file, line: line)
    }
}

func XCTAssertTrackResultIsAccepted(
    _ result: TrackResult,
    withAsserts asserts: (Dispatch) -> Void = { _ in },
    file: StaticString = #filePath,
    line: UInt = #line
) {
    switch result.status {
    case .dropped:
        XCTFail("Expected to be accepted but got dropped", file: file, line: line)
    case .accepted:
        asserts(result.dispatch)
    }
}

func XCTAssertTrackResultIsDropped(
    _ result: TrackResult,
    withAsserts asserts: (Dispatch) -> Void = { _ in },
    file: StaticString = #filePath,
    line: UInt = #line
) {
    switch result.status {
    case .dropped:
        asserts(result.dispatch)
    case .accepted:
        XCTFail("Expected to be dropped but got accepted", file: file, line: line)
    }
}

func XCTAssertNoThrowReturn<T>(
    _ expression: @autoclosure () throws -> T,
    in file: StaticString = #file,
    line: UInt = #line
) -> T? {
    do {
        return try expression()
    } catch {
        XCTFail(
            error.localizedDescription,
            file: file,
            line: line
        )
    }
    return nil
}
