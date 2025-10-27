//
//  JSONObjectPathParseTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class JSONObjectPathParseTests: XCTestCase {

    func test_parse_simple_property() throws {
        let parsedPath = try JSONObjectPath.parse("container.property")
        let expectedPath = JSONPath["container"]["property"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_simple_property_with_numbers() throws {
        let parsedPath = try JSONObjectPath.parse("container.property123")
        let expectedPath = JSONPath["container"]["property123"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_simple_property_with_underscores() throws {
        let parsedPath = try JSONObjectPath.parse("container.a_property")
        let expectedPath = JSONPath["container"]["a_property"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_simple_property_starting_with_underscore() throws {
        let parsedPath = try JSONObjectPath.parse("container._property")
        let expectedPath = JSONPath["container"]["_property"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_simple_property_starting_with_number() throws {
        let parsedPath = try JSONObjectPath.parse("container.1property")
        let expectedPath = JSONPath["container"]["1property"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_array_index() throws {
        let parsedPath = try JSONObjectPath.parse("container.array[2]")
        let expectedPath = JSONPath["container"]["array"][2]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_single_key() throws {
        let parsedPath = try JSONObjectPath.parse("container")
        let expectedPath = JSONPath["container"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_empty_string_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_invalid_array_index_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("container.array[invalid]")) { (parseError: JSONPathParseError) in
            guard case let .invalidArrayIndex(index) = parseError.kind else {
                XCTFail("Expected invalidArrayIndex error, but got: \(parseError)")
                return
            }
            XCTAssertEqual(index, "invalid")
        }
    }

    func test_parse_missing_closing_quote_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("container[\"invalid]")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unclosedQuotedKey error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_terminating_before_closing_quoted_bracket_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("container[\"invalid\"")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_missing_closing_quoted_bracket_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("container[\"invalid\"property")) { (parseError: JSONPathParseError) in
            guard case .unclosedQuotedKey = parseError.kind else {
                XCTFail("Expected unclosedQuotedKey error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_missing_closing_bracket_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("container[123")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_ending_with_opening_bracket_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("container[")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_starting_with_dot_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse(".invalid")) { (parseError: JSONPathParseError) in
            guard case .emptyPathComponent = parseError.kind else {
                XCTFail("Expected emptyPathComponent error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_starting_with_array_index_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("[123]")) { (parseError: JSONPathParseError) in
            guard case .invalidFirstComponent = parseError.kind else {
                XCTFail("Expected invalidFirstComponent error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_single_open_quote_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("[")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_quoted_key() throws {
        let parsedPath = try JSONObjectPath.parse("container[\"special.key\"]")
        let expectedPath = JSONPath["container"]["special.key"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_starting_with_quoted_key() throws {
        let parsedPath = try JSONObjectPath.parse("[\"special.key\"].property")
        let expectedPath = JSONPath["special.key"]["property"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_multiple_quoted_keys() throws {
        let parsedPath = try JSONObjectPath.parse("[\"special.key\"][\"other.key\"]")
        let expectedPath = JSONPath["special.key"]["other.key"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_multiple_array_indexes() throws {
        let parsedPath = try JSONObjectPath.parse("matrix[123][456]")
        let expectedPath = JSONPath["matrix"][123][456]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_invalid_key_character_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("special-key")) { (parseError: JSONPathParseError) in
            guard case let .invalidCharacter(character, position) = parseError.kind else {
                XCTFail("Expected invalidCharacter error, but got: \(parseError)")
                return
            }
            XCTAssertEqual(character, "-")
            XCTAssertEqual(position, 7)
        }
    }

    func test_parse_invalid_key_character_in_middle_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("valid.key@special")) { (parseError: JSONPathParseError) in
            guard case let .invalidCharacter(character, position) = parseError.kind else {
                XCTFail("Expected invalidCharacter error, but got: \(parseError)")
                return
            }
            XCTAssertEqual(character, "@")
            XCTAssertEqual(position, 9)
        }
    }

    func test_parse_invalid_key_character_in_quoted_brackets_makes_it_valid() throws {
        let parsedPath = try JSONObjectPath.parse("valid[\"key@special\"]")
        let expectedPath = JSONPath["valid"]["key@special"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_two_dots_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("invalid..key")) { (parseError: JSONPathParseError) in
            guard case .emptyPathComponent = parseError.kind else {
                XCTFail("Expected emptyPathComponent error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_key_without_separator_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("[\"key\"]key")) { (parseError: JSONPathParseError) in
            guard case let .missingSeparator(position) = parseError.kind else {
                XCTFail("Expected missingSeparator error, but got: \(parseError)")
                return
            }
            XCTAssertEqual(position, 7)
        }
    }

    func test_parse_empty_quoted_string_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("[\"\"]")) { (parseError: JSONPathParseError) in
            guard case .emptyPathComponent = parseError.kind else {
                XCTFail("Expected emptyPathComponent error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_empty_array_index_throws_error() {
        XCTAssertThrows(try JSONObjectPath.parse("array[]")) { (parseError: JSONPathParseError) in
            guard case .emptyPathComponent = parseError.kind else {
                XCTFail("Expected emptyPathComponent error, but got: \(parseError)")
                return
            }
        }
    }
}
