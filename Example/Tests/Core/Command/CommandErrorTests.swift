//
//  CommandErrorTests.swift
//  TealiumPrismCoreTests
//
//  Copyright © 2026 Tealium. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class CommandErrorTests: XCTestCase {

    func test_invalidParameterValue_message_includes_parameter_and_reason() {
        let error = CommandError.invalidParameterValue(parameter: "gender", reason: "expected one of m, f")

        XCTAssertEqual(error.message, "Invalid value for 'gender' - expected one of m, f")
    }

    func test_noValidParameters_message_lists_expected_parameters() {
        let error = CommandError.noValidParameters(expected: ["a", "b"])

        XCTAssertEqual(error.message, "No valid parameter found. Expected one of: 'a', 'b'")
    }

    func test_noValidParameters_message_omits_expected_when_none_are_given() {
        let error = CommandError.noValidParameters(expected: [])

        XCTAssertEqual(error.message, "No valid parameter found.")
    }

    func test_underlyingError_message_includes_error() {
        let error = CommandError.underlyingError(TestError.unknown)

        XCTAssertEqual(error.message, "Command failed due to error: unknown")
    }
}
