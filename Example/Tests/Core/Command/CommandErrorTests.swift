//
//  CommandErrorTests.swift
//  TealiumPrismCoreTests
//
//  Copyright © 2026 Tealium. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class CommandErrorTests: XCTestCase {

    func test_invalidPayload_missing_message_includes_key() {
        let error = CommandError.invalidPayload(.missing(key: "gender"))

        XCTAssertEqual(error.message, "Missing required value for 'gender'")
    }

    func test_invalidPayload_typeMismatch_message_includes_key_and_expected_type() {
        let error = CommandError.invalidPayload(.typeMismatch(key: "age", expectedType: "Int"))

        XCTAssertEqual(error.message, "Invalid type for 'age' - expected Int")
    }

    func test_invalidPayload_invalidValue_message_includes_key_and_reason() {
        let error = CommandError.invalidPayload(.invalidValue(key: "gender", reason: "expected one of m, f"))

        XCTAssertEqual(error.message, "Invalid value for 'gender' - expected one of m, f")
    }

    func test_invalidPayload_empty_message_includes_key() {
        let error = CommandError.invalidPayload(.empty(key: "name"))

        XCTAssertEqual(error.message, "Empty value for 'name'")
    }

    @available(*, deprecated)
    func test_missingParameter_message_includes_parameter() {
        let error = CommandError.missingParameter("name")

        XCTAssertEqual(error.message, "Missing required parameter 'name'")
    }

    @available(*, deprecated)
    func test_invalidParameterType_message_includes_parameter_and_expected_type() {
        let error = CommandError.invalidParameterType(parameter: "age", expectedType: "Int")

        XCTAssertEqual(error.message, "Invalid type for 'age' - expected Int")
    }

    @available(*, deprecated)
    func test_emptyParameter_message_includes_parameter() {
        let error = CommandError.emptyParameter("name")

        XCTAssertEqual(error.message, "Parameter 'name' is empty")
    }

    @available(*, deprecated)
    func test_emptyArray_message_includes_parameter() {
        let error = CommandError.emptyArray("items")

        XCTAssertEqual(error.message, "Array 'items' is empty")
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
