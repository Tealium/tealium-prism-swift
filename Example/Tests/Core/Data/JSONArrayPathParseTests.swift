//
//  JSONArrayPathParseTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class JSONArrayPathParseTests: XCTestCase {

    func test_parse_simple_property() throws {
        let parsedPath = try JSONArrayPath.parse("[0].property")
        let expectedPath = JSONPath[0]["property"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_simple_property_with_numbers() throws {
        let parsedPath = try JSONArrayPath.parse("[0].property123")
        let expectedPath = JSONPath[0]["property123"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_simple_property_with_underscores() throws {
        let parsedPath = try JSONArrayPath.parse("[0].a_property")
        let expectedPath = JSONPath[0]["a_property"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_simple_property_starting_with_underscore() throws {
        let parsedPath = try JSONArrayPath.parse("[0]._property")
        let expectedPath = JSONPath[0]["_property"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_simple_property_starting_with_number() throws {
        let parsedPath = try JSONArrayPath.parse("[0].1property")
        let expectedPath = JSONPath[0]["1property"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_array_index() throws {
        let parsedPath = try JSONArrayPath.parse("[0].array[2]")
        let expectedPath = JSONPath[0]["array"][2]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_single_index() throws {
        let parsedPath = try JSONArrayPath.parse("[0]")
        let expectedPath = JSONPath[0]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_empty_string_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_invalid_array_index_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[invalid]")) { (parseError: JSONPathParseError) in
            guard case let .invalidArrayIndex(index) = parseError.kind else {
                XCTFail("Expected invalidArrayIndex error, but got: \(parseError)")
                return
            }
            XCTAssertEqual(index, "invalid")
        }
    }

    func test_parse_missing_closing_quote_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[0][\"invalid]")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unclosedQuotedKey error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_terminating_before_closing_quoted_bracket_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[0][\"invalid\"")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_missing_closing_quoted_bracket_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[0][\"invalid\"property")) { (parseError: JSONPathParseError) in
            guard case .unclosedQuotedKey = parseError.kind else {
                XCTFail("Expected unclosedQuotedKey error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_missing_closing_bracket_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[123")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_ending_with_opening_bracket_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[0][")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_starting_with_dot_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse(".invalid")) { (parseError: JSONPathParseError) in
            guard case .emptyPathComponent = parseError.kind else {
                XCTFail("Expected emptyPathComponent error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_starting_with_key_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("property")) { (parseError: JSONPathParseError) in
            guard case .invalidFirstComponent = parseError.kind else {
                XCTFail("Expected invalidFirstComponent error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_single_open_quote_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[")) { (parseError: JSONPathParseError) in
            guard case .unexpectedEndOfInput = parseError.kind else {
                XCTFail("Expected unexpectedEndOfInput error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_quoted_key() throws {
        let parsedPath = try JSONArrayPath.parse("[0][\"special.key\"]")
        let expectedPath = JSONPath[0]["special.key"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_starting_with_quoted_key_throws_error() throws {
        XCTAssertThrows(try JSONArrayPath.parse("[\"123\"]")) { (parseError: JSONPathParseError) in
            guard case .invalidFirstComponent = parseError.kind else {
                XCTFail("Expected invalidFirstComponent error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_multiple_quoted_keys() throws {
        let parsedPath = try JSONArrayPath.parse("[0][\"special.key\"][\"other.key\"]")
        let expectedPath = JSONPath[0]["special.key"]["other.key"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_multiple_array_indexes() throws {
        let parsedPath = try JSONArrayPath.parse("[123][456]")
        let expectedPath = JSONPath[123][456]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_invalid_key_character_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[0].special-key")) { (parseError: JSONPathParseError) in
            guard case let .invalidCharacter(character, position) = parseError.kind else {
                XCTFail("Expected invalidCharacter error, but got: \(parseError)")
                return
            }
            XCTAssertEqual(character, "-")
            XCTAssertEqual(position, 11)
        }
    }

    func test_parse_invalid_key_character_in_middle_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[0].valid.key@special")) { (parseError: JSONPathParseError) in
            guard case let .invalidCharacter(character, position) = parseError.kind else {
                XCTFail("Expected invalidCharacter error, but got: \(parseError)")
                return
            }
            XCTAssertEqual(character, "@")
            XCTAssertEqual(position, 13)
        }
    }

    func test_parse_invalid_key_character_in_quoted_brackets_makes_it_valid() throws {
        let parsedPath = try JSONArrayPath.parse("[0].valid[\"key@special\"]")
        let expectedPath = JSONPath[0]["valid"]["key@special"]
        XCTAssertEqual(parsedPath, expectedPath)
    }

    func test_parse_two_dots_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[0].invalid..key")) { (parseError: JSONPathParseError) in
            guard case .emptyPathComponent = parseError.kind else {
                XCTFail("Expected emptyPathComponent error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_key_without_separator_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[0]key")) { (parseError: JSONPathParseError) in
            guard case let .missingSeparator(position) = parseError.kind else {
                XCTFail("Expected missingSeparator error, but got: \(parseError)")
                return
            }
            XCTAssertEqual(position, 3)
        }
    }

    func test_parse_empty_quoted_string_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[\"\"]")) { (parseError: JSONPathParseError) in
            guard case .emptyPathComponent = parseError.kind else {
                XCTFail("Expected emptyPathComponent error, but got: \(parseError)")
                return
            }
        }
    }

    func test_parse_empty_array_index_throws_error() {
        XCTAssertThrows(try JSONArrayPath.parse("[]")) { (parseError: JSONPathParseError) in
            guard case .emptyPathComponent = parseError.kind else {
                XCTFail("Expected emptyPathComponent error, but got: \(parseError)")
                return
            }
        }
    }
}
