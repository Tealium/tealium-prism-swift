//
//  DataItemExtractorFailableExtractionTests.swift
//  TealiumPrismCoreTests
//
//  Created by Sebastian Krajna on 10/11/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DataItemExtractorFailableExtractionTests: XCTestCase {

    // MARK: - requireDataItem

    func test_requireDataItem_returns_item_when_present() throws {
        let payload: DataObject = ["user_id": "abc"]

        XCTAssertEqual(try payload.requireDataItem(Destination.userId).get(as: String.self), "abc")
    }

    func test_requireDataItem_throws_missing_when_absent() {
        let payload: DataObject = ["other": "abc"]

        let error = thrownError { try payload.requireDataItem(Destination.userId) }

        guard case .missing(let name) = error else {
            return XCTFail("Expected ExtractionError.missing but got \(String(describing: error))")
        }
        XCTAssertEqual(name, "user_id")
    }

    func test_requireDataItem_renders_nested_path_in_error() {
        let payload: DataObject = ["parameters": ["other": "abc"]]

        let error = thrownError { try payload.requireDataItem(Destination.nestedUserId) }

        guard case .missing(let name) = error else {
            return XCTFail("Expected ExtractionError.missing but got \(String(describing: error))")
        }
        XCTAssertEqual(name, "parameters.user_id")
    }

    func test_requireDataItem_reads_nested_value() throws {
        let payload: DataObject = ["parameters": ["user_id": "abc"]]

        XCTAssertEqual(try payload.requireDataItem(Destination.nestedUserId).get(as: String.self), "abc")
    }

    // MARK: - requireDataDictionary

    func test_requireDataDictionary_returns_dictionary_when_present() throws {
        let payload: DataObject = ["user_id": ["key": "value"]]

        let dictionary = try payload.requireDataDictionary(Destination.userId)

        XCTAssertEqual(dictionary.get(key: "key", as: String.self), "value")
    }

    func test_requireDataDictionary_throws_missing_when_absent() {
        let payload: DataObject = [:]

        let error = thrownError { try payload.requireDataDictionary(Destination.userId) }

        guard case .missing(let name) = error else {
            return XCTFail("Expected ExtractionError.missing but got \(String(describing: error))")
        }
        XCTAssertEqual(name, "user_id")
    }

    func test_requireDataDictionary_throws_typeMismatch_when_not_a_dictionary() {
        let payload: DataObject = ["user_id": "abc"]

        let error = thrownError { try payload.requireDataDictionary(Destination.userId) }

        guard case let .typeMismatch(parameter, expectedType) = error else {
            return XCTFail("Expected ExtractionError.typeMismatch but got \(String(describing: error))")
        }
        XCTAssertEqual(parameter, "user_id")
        XCTAssertEqual(expectedType, "Dictionary<String, DataItem>")
    }

    // MARK: - require(_:converter:)

    func test_require_returns_converted_value() throws {
        let payload: DataObject = ["user_id": "abc"]

        XCTAssertEqual(try payload.require(Destination.userId, converter: LenientConverters.string), "abc")
    }

    func test_require_uses_lenient_converter() throws {
        let payload: DataObject = ["user_id": "42"]

        XCTAssertEqual(try payload.require(Destination.userId, converter: LenientConverters.int), 42)
    }

    func test_require_converts_number_to_string_with_lenient_string_converter() throws {
        let payload: DataObject = ["user_id": 42]

        XCTAssertEqual(try payload.require(Destination.userId, converter: LenientConverters.string), "42")
    }

    func test_require_throws_missing_when_absent() {
        let payload: DataObject = [:]

        let error = thrownError { try payload.require(Destination.userId, converter: LenientConverters.string) }

        guard case .missing(let name) = error else {
            return XCTFail("Expected ExtractionError.missing but got \(String(describing: error))")
        }
        XCTAssertEqual(name, "user_id")
    }

    func test_require_throws_typeMismatch_when_conversion_fails() {
        let payload: DataObject = ["user_id": ["key": "value"]]

        let error = thrownError { try payload.require(Destination.userId, converter: LenientConverters.string) }

        guard case let .typeMismatch(parameter, expectedType) = error else {
            return XCTFail("Expected ExtractionError.typeMismatch but got \(String(describing: error))")
        }
        XCTAssertEqual(parameter, "user_id")
        XCTAssertEqual(expectedType, "String")
    }

    func test_require_throws_typeMismatch_when_lenient_int_conversion_fails() {
        let payload: DataObject = ["user_id": "abc"]

        let error = thrownError { try payload.require(Destination.userId, converter: LenientConverters.int) }

        guard case let .typeMismatch(parameter, expectedType) = error else {
            return XCTFail("Expected ExtractionError.typeMismatch but got \(String(describing: error))")
        }
        XCTAssertEqual(parameter, "user_id")
        XCTAssertEqual(expectedType, "Int")
    }

    func test_require_throws_typeMismatch_when_lenient_bool_conversion_fails() {
        let payload: DataObject = ["user_id": "maybe"]

        let error = thrownError { try payload.require(Destination.userId, converter: LenientConverters.bool) }

        assertInvalidType("user_id", "Bool", error)
    }

    func test_require_throws_typeMismatch_when_lenient_double_conversion_fails() {
        let payload: DataObject = ["user_id": "abc"]

        let error = thrownError { try payload.require(Destination.userId, converter: LenientConverters.double) }

        assertInvalidType("user_id", "Double", error)
    }

    // MARK: - optional(_:converter:)

    func test_optional_returns_nil_when_absent() throws {
        let payload: DataObject = [:]

        XCTAssertNil(try payload.optional(Destination.userId, converter: LenientConverters.string))
    }

    func test_optional_returns_nil_when_explicit_null() throws {
        let payload: DataObject = ["user_id": DataItem.null]

        XCTAssertNil(try payload.optional(Destination.userId, converter: LenientConverters.string))
    }

    func test_optional_returns_converted_value_when_present() throws {
        let payload: DataObject = ["user_id": "abc"]

        XCTAssertEqual(try payload.optional(Destination.userId, converter: LenientConverters.string), "abc")
    }

    func test_optional_uses_lenient_converter() throws {
        let payload: DataObject = ["user_id": "42"]

        XCTAssertEqual(try payload.optional(Destination.userId, converter: LenientConverters.int), 42)
    }

    func test_optional_throws_typeMismatch_when_conversion_fails() {
        let payload: DataObject = ["user_id": "abc"]

        let error = thrownError { try payload.optional(Destination.userId, converter: LenientConverters.int) }

        guard case let .typeMismatch(parameter, expectedType) = error else {
            return XCTFail("Expected ExtractionError.typeMismatch but got \(String(describing: error))")
        }
        XCTAssertEqual(parameter, "user_id")
        XCTAssertEqual(expectedType, "Int")
    }

    // MARK: - optionalDataDictionary

    func test_optionalDataDictionary_returns_nil_when_absent() throws {
        let payload: DataObject = [:]

        XCTAssertNil(try payload.optionalDataDictionary(Destination.userId))
    }

    func test_optionalDataDictionary_returns_nil_when_explicit_null() throws {
        let payload: DataObject = ["user_id": DataItem.null]

        XCTAssertNil(try payload.optionalDataDictionary(Destination.userId))
    }

    func test_optionalDataDictionary_returns_dictionary_when_present() throws {
        let payload: DataObject = ["user_id": ["key": "value"]]

        let dictionary = try payload.optionalDataDictionary(Destination.userId)

        XCTAssertEqual(dictionary?.get(key: "key", as: String.self), "value")
    }

    func test_optionalDataDictionary_throws_typeMismatch_when_not_a_dictionary() {
        let payload: DataObject = ["user_id": "abc"]

        let error = thrownError { try payload.optionalDataDictionary(Destination.userId) }

        guard case let .typeMismatch(parameter, expectedType) = error else {
            return XCTFail("Expected ExtractionError.typeMismatch but got \(String(describing: error))")
        }
        XCTAssertEqual(parameter, "user_id")
        XCTAssertEqual(expectedType, "Dictionary<String, DataItem>")
    }

    // MARK: - Explicit null handling

    func test_requireDataItem_returns_null_item_when_explicit_null() throws {
        let payload: DataObject = ["user_id": DataItem.null]

        XCTAssertTrue(try payload.requireDataItem(Destination.userId).value is NSNull)
    }

    func test_requireDataDictionary_throws_missing_when_explicit_null() {
        let payload: DataObject = ["user_id": DataItem.null]

        assertMissing("user_id", thrownError { try payload.requireDataDictionary(Destination.userId) })
    }

    func test_require_throws_missing_when_explicit_null() {
        let payload: DataObject = ["user_id": DataItem.null]

        assertMissing("user_id", thrownError { try payload.require(Destination.userId, converter: LenientConverters.string) })
    }

    // MARK: - requireNonBlank

    func test_requireNonBlank_returns_value_untrimmed() throws {
        let payload: DataObject = ["user_id": "  abc \n"]

        XCTAssertEqual(try payload.requireNonBlank(Destination.userId, converter: LenientConverters.string), "  abc \n")
    }

    func test_requireNonBlank_throws_missing_when_absent() {
        let payload: DataObject = [:]

        assertMissing("user_id", thrownError { try payload.requireNonBlank(Destination.userId, converter: LenientConverters.string) })
    }

    func test_requireNonBlank_throws_missing_when_explicit_null() {
        let payload: DataObject = ["user_id": DataItem.null]

        assertMissing("user_id", thrownError { try payload.requireNonBlank(Destination.userId, converter: LenientConverters.string) })
    }

    func test_requireNonBlank_throws_typeMismatch_when_not_convertible() {
        let payload: DataObject = ["user_id": ["key": "value"]]

        let error = thrownError { try payload.requireNonBlank(Destination.userId, converter: LenientConverters.string) }

        assertInvalidType("user_id", "String", error)
    }

    func test_requireNonBlank_throws_empty_when_empty_or_whitespace() {
        for blank in ["", " ", "\t", "\n", "   ", " \n\t "] {
            let payload: DataObject = ["user_id": DataItem(value: blank)]

            let error = thrownError { try payload.requireNonBlank(Destination.userId, converter: LenientConverters.string) }

            guard case .empty(let name) = error else {
                return XCTFail("Expected ExtractionError.empty but got \(String(describing: error))")
            }
            XCTAssertEqual(name, "user_id")
        }
    }

    // MARK: - requireOneOf

    func test_requireOneOf_returns_mapped_value() throws {
        let payload: DataObject = ["user_id": "high"]

        XCTAssertEqual(try payload.requireOneOf(Destination.userId, values: Level.values), .high)
    }

    func test_requireOneOf_matches_case_insensitively_after_trimming() throws {
        let payload: DataObject = ["user_id": " \nHiGh\t "]

        XCTAssertEqual(try payload.requireOneOf(Destination.userId, values: Level.values), .high)
    }

    func test_requireOneOf_reads_non_string_leniently() throws {
        let payload: DataObject = ["user_id": true]

        XCTAssertEqual(try payload.requireOneOf(Destination.userId, values: ["true": 1, "false": 0]), 1)
    }

    func test_requireOneOf_throws_missing_when_absent_or_null() {
        assertMissing("user_id", thrownError { try DataObject().requireOneOf(Destination.userId, values: Level.values) })
        let payload: DataObject = ["user_id": DataItem.null]
        assertMissing("user_id", thrownError { try payload.requireOneOf(Destination.userId, values: Level.values) })
    }

    func test_requireOneOf_throws_empty_when_blank() {
        for blank in ["", "\t", "\n", " "] {
            let payload: DataObject = ["user_id": DataItem(value: blank)]

            let error = thrownError { try payload.requireOneOf(Destination.userId, values: Level.values) }

            guard case .empty(let name) = error else {
                return XCTFail("Expected ExtractionError.empty but got \(String(describing: error))")
            }
            XCTAssertEqual(name, "user_id")
        }
    }

    func test_requireOneOf_throws_typeMismatch_when_array() {
        let payload: DataObject = ["user_id": DataItem(value: ["low", "high"])]

        assertInvalidType("user_id", "String", thrownError { try payload.requireOneOf(Destination.userId, values: Level.values) })
    }

    func test_requireOneOf_throws_typeMismatch_when_not_string_convertible() {
        let payload: DataObject = ["user_id": ["key": "value"]]

        assertInvalidType("user_id", "String", thrownError { try payload.requireOneOf(Destination.userId, values: Level.values) })
    }

    func test_requireOneOf_throws_invalidValue_listing_keys_sorted_ignoring_case() {
        let payload: DataObject = ["user_id": "secret"]

        let error = thrownError { try payload.requireOneOf(Destination.userId, values: Level.values) }

        assertInvalidValue("user_id", "expected one of high, low, MAX", error)
    }

    func test_requireOneOf_renders_nested_path_in_error() {
        let payload: DataObject = ["parameters": ["user_id": "nope"]]

        let error = thrownError { try payload.requireOneOf(Destination.nestedUserId, values: Level.values) }

        assertInvalidValue("parameters.user_id", "expected one of high, low, MAX", error)
    }

    // MARK: - Raw JSONPath as parameter

    func test_require_accepts_raw_JSONPath() throws {
        let payload: DataObject = ["parameters": ["AD_STORAGE": "granted"]]

        XCTAssertEqual(try payload.require(JSONPath["parameters"]["AD_STORAGE"], converter: LenientConverters.string), "granted")
    }

    func test_require_renders_child_path_of_raw_JSONPath_in_error() {
        let payload: DataObject = ["parameters": [:] as DataObject]

        let error = thrownError { try payload.require(Destination.nestedUserId.path["AD_STORAGE"], converter: LenientConverters.string) }

        assertMissing("parameters.user_id.AD_STORAGE", error)
    }

    func test_requireOneOf_accepts_raw_JSONPath_and_renders_it_in_error() throws {
        let payload: DataObject = ["parameters": ["AD_STORAGE": "high", "OTHER": "nope"]]

        XCTAssertEqual(try payload.requireOneOf(JSONPath["parameters"]["AD_STORAGE"], values: Level.values), .high)
        let error = thrownError { try payload.requireOneOf(JSONPath["parameters"]["OTHER"], values: Level.values) }
        assertInvalidValue("parameters.OTHER", "expected one of high, low, MAX", error)
    }

    func test_requireOneOf_throws_missing_when_raw_JSONPath_child_absent_or_null() {
        let absent: DataObject = ["parameters": [:] as DataObject]
        assertMissing("parameters.AD_STORAGE", thrownError { try absent.requireOneOf(JSONPath["parameters"]["AD_STORAGE"], values: Level.values) })
        let null: DataObject = ["parameters": ["AD_STORAGE": DataItem.null]]
        assertMissing("parameters.AD_STORAGE", thrownError { try null.requireOneOf(JSONPath["parameters"]["AD_STORAGE"], values: Level.values) })
    }

    func test_requireOneOf_throws_empty_when_raw_JSONPath_child_blank() {
        let payload: DataObject = ["parameters": ["AD_STORAGE": " "]]

        let error = thrownError { try payload.requireOneOf(JSONPath["parameters"]["AD_STORAGE"], values: Level.values) }

        guard case .empty(let name) = error else {
            return XCTFail("Expected ExtractionError.empty but got \(String(describing: error))")
        }
        XCTAssertEqual(name, "parameters.AD_STORAGE")
    }

    func test_optionalOneOf_returns_nil_when_raw_JSONPath_child_absent_null_or_blank() throws {
        let payloads: [DataObject] = [
            ["parameters": [:] as DataObject],
            ["parameters": ["AD_STORAGE": DataItem.null]],
            ["parameters": ["AD_STORAGE": " "]]
        ]
        for payload in payloads {
            XCTAssertNil(try payload.optionalOneOf(JSONPath["parameters"]["AD_STORAGE"], values: Level.values))
        }
    }

    // MARK: - optionalOneOf

    func test_optionalOneOf_returns_mapped_value() throws {
        let payload: DataObject = ["user_id": " max "]

        XCTAssertEqual(try payload.optionalOneOf(Destination.userId, values: Level.values), .max)
    }

    func test_optionalOneOf_reads_non_string_leniently() throws {
        let payload: DataObject = ["user_id": false]

        XCTAssertEqual(try payload.optionalOneOf(Destination.userId, values: ["true": 1, "false": 0]), 0)
    }

    func test_optionalOneOf_returns_nil_when_absent_or_null() throws {
        XCTAssertNil(try DataObject().optionalOneOf(Destination.userId, values: Level.values))
        let null: DataObject = ["user_id": DataItem.null]
        XCTAssertNil(try null.optionalOneOf(Destination.userId, values: Level.values))
    }

    func test_optionalOneOf_returns_nil_when_blank() throws {
        for blank in ["", "\t", "\n", " "] {
            let payload: DataObject = ["user_id": DataItem(value: blank)]

            XCTAssertNil(try payload.optionalOneOf(Destination.userId, values: Level.values))
        }
    }

    func test_optionalOneOf_throws_typeMismatch_when_array() {
        let payload: DataObject = ["user_id": DataItem(value: ["low", "high"])]

        assertInvalidType("user_id", "String", thrownError { try payload.optionalOneOf(Destination.userId, values: Level.values) })
    }

    func test_optionalOneOf_throws_typeMismatch_when_not_string_convertible() {
        let payload: DataObject = ["user_id": ["key": "value"]]

        assertInvalidType("user_id", "String", thrownError { try payload.optionalOneOf(Destination.userId, values: Level.values) })
    }

    func test_optionalOneOf_throws_invalidValue_when_unknown() {
        let payload: DataObject = ["user_id": "secret"]

        let error = thrownError { try payload.optionalOneOf(Destination.userId, values: Level.values) }

        assertInvalidValue("user_id", "expected one of high, low, MAX", error)
    }
}

private enum Level: Equatable {
    case low, high, max

    static let values: [String: Level] = ["low": .low, "high": .high, "MAX": .max]
}

private func assertMissing(_ expected: String, _ error: ExtractionError?, file: StaticString = #filePath, line: UInt = #line) {
    guard case .missing(let name) = error else {
        return XCTFail("Expected ExtractionError.missing but got \(String(describing: error))", file: file, line: line)
    }
    XCTAssertEqual(name, expected, file: file, line: line)
}

private func assertInvalidType(_ expected: String, _ expectedType: String, _ error: ExtractionError?, file: StaticString = #filePath, line: UInt = #line) {
    guard case let .typeMismatch(parameter, type) = error else {
        return XCTFail("Expected ExtractionError.typeMismatch but got \(String(describing: error))", file: file, line: line)
    }
    XCTAssertEqual(parameter, expected, file: file, line: line)
    XCTAssertEqual(type, expectedType, file: file, line: line)
}

private func assertInvalidValue(_ expected: String, _ expectedReason: String, _ error: ExtractionError?, file: StaticString = #filePath, line: UInt = #line) {
    guard case let .invalidValue(parameter, reason) = error else {
        return XCTFail("Expected ExtractionError.invalidValue but got \(String(describing: error))", file: file, line: line)
    }
    XCTAssertEqual(parameter, expected, file: file, line: line)
    XCTAssertEqual(reason, expectedReason, file: file, line: line)
}

private enum Destination: JSONObjectPathConvertible {
    case userId
    case nestedUserId

    var path: JSONObjectPath {
        switch self {
        case .userId: JSONPath["user_id"]
        case .nestedUserId: JSONPath["parameters"]["user_id"]
        }
    }
}

private func thrownError<T>(_ body: () throws -> T) -> ExtractionError? {
    do {
        _ = try body()
        return nil
    } catch {
        return error as? ExtractionError
    }
}
