//
//  DataItem+JSONStringTests.swift
//  CoreTests
//
//  Created by Claude on 02/07/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class DataItemJSONStringTests: XCTestCase {

    // MARK: - init(jsonString:) Tests

    func test_init_with_integer_json_string() throws {
        let item = try DataItem(jsonString: "42")
        XCTAssertEqual(item.get(), 42)
    }

    func test_init_with_double_json_string() throws {
        let item = try DataItem(jsonString: "3.14")
        XCTAssertEqual(item.get(), 3.14)
    }

    func test_init_with_boolean_true_json_string() throws {
        let item = try DataItem(jsonString: "true")
        XCTAssertEqual(item.get(), true)
    }

    func test_init_with_boolean_false_json_string() throws {
        let item = try DataItem(jsonString: "false")
        XCTAssertEqual(item.get(), false)
    }

    func test_init_with_string_json_string() throws {
        let item = try DataItem(jsonString: "\"hello\"")
        XCTAssertEqual(item.get(), "hello")
    }

    func test_init_with_null_json_string() throws {
        let item = try DataItem(jsonString: "null")
        XCTAssertNSNull(item.toDataInput())
    }

    func test_init_with_array_json_string() throws {
        let item = try DataItem(jsonString: "[1,2,3]")
        XCTAssertEqual(item.getArray(), [1, 2, 3])
    }

    func test_init_with_dictionary_json_string() throws {
        let item = try DataItem(jsonString: "{\"key\":\"value\"}")
        let dict = item.getDataDictionary()
        XCTAssertEqual(dict?.get(key: "key"), "value")
    }

    func test_init_with_invalid_json_string_throws_error() {
        XCTAssertThrowsError(try DataItem(jsonString: "not valid json")) { error in
            guard case JSONParsingError.invalidJSON = error else {
                XCTFail("Expected JSONParsingError.invalidJSON, got \(error)")
                return
            }
        }
    }

    func test_init_with_empty_string_throws_error() {
        XCTAssertThrowsError(try DataItem(jsonString: "")) { error in
            guard case JSONParsingError.invalidJSON = error else {
                XCTFail("Expected JSONParsingError.invalidJSON, got \(error)")
                return
            }
        }
    }

    // MARK: - serialize() Tests

    func test_serialize_integer() throws {
        let item = DataItem(value: 42)
        XCTAssertEqual(try item.serialize(), "42")
    }

    func test_serialize_double() throws {
        let item = DataItem(value: 3.14)
        XCTAssertEqual(try item.serialize(), "3.14")
    }

    func test_serialize_boolean_true() throws {
        let item = DataItem(value: true)
        XCTAssertEqual(try item.serialize(), "true")
    }

    func test_serialize_boolean_false() throws {
        let item = DataItem(value: false)
        XCTAssertEqual(try item.serialize(), "false")
    }

    func test_serialize_string() throws {
        let item = DataItem(value: "hello")
        XCTAssertEqual(try item.serialize(), "\"hello\"")
    }

    func test_serialize_null() throws {
        let item = DataItem.null
        XCTAssertEqual(try item.serialize(), "null")
    }

    func test_serialize_array() throws {
        let item = DataItem(value: [1, 2, 3])
        XCTAssertEqual(try item.serialize(), "[1,2,3]")
    }

    func test_serialize_dictionary() throws {
        let item = DataItem(value: ["key": "value"])
        let serialized = try item.serialize()
        XCTAssertTrue(serialized == "{\"key\":\"value\"}")
    }

    // MARK: - Roundtrip Tests

    func test_roundtrip_integer() throws {
        let original = "42"
        let item = try DataItem(jsonString: original)
        let serialized = try item.serialize()
        XCTAssertEqual(serialized, original)
    }

    func test_roundtrip_double() throws {
        let original = "3.14"
        let item = try DataItem(jsonString: original)
        let serialized = try item.serialize()
        XCTAssertEqual(serialized, original)
    }

    func test_roundtrip_boolean_true() throws {
        let original = "true"
        let item = try DataItem(jsonString: original)
        let serialized = try item.serialize()
        XCTAssertEqual(serialized, original)
    }

    func test_roundtrip_boolean_false() throws {
        let original = "false"
        let item = try DataItem(jsonString: original)
        let serialized = try item.serialize()
        XCTAssertEqual(serialized, original)
    }

    func test_roundtrip_string() throws {
        let original = "\"hello\""
        let item = try DataItem(jsonString: original)
        let serialized = try item.serialize()
        XCTAssertEqual(serialized, original)
    }

    func test_roundtrip_null() throws {
        let original = "null"
        let item = try DataItem(jsonString: original)
        let serialized = try item.serialize()
        XCTAssertEqual(serialized, original)
    }

    func test_roundtrip_array() throws {
        let original = "[1,2,3]"
        let item = try DataItem(jsonString: original)
        let serialized = try item.serialize()
        XCTAssertEqual(serialized, original)
    }

    func test_roundtrip_nested_array() throws {
        let original = "[[1,2],[3,4]]"
        let item = try DataItem(jsonString: original)
        let serialized = try item.serialize()
        XCTAssertEqual(serialized, original)
    }

    func test_roundtrip_complex_dictionary() throws {
        let jsonString = "{\"name\":\"test\",\"count\":42,\"active\":true,\"tags\":[\"a\",\"b\"]}"
        let item = try DataItem(jsonString: jsonString)
        let serialized = try item.serialize()

        // Parse both to verify semantic equality (order may differ)
        let originalParsed = try DataItem(jsonString: jsonString)
        let roundtripParsed = try DataItem(jsonString: serialized)

        let originalDict = originalParsed.getDataDictionary()
        let roundtripDict = roundtripParsed.getDataDictionary()

        XCTAssertEqual(originalDict?.get(key: "name"), "test")
        XCTAssertEqual(roundtripDict?.get(key: "name"), "test")
        XCTAssertEqual(originalDict?.get(key: "count"), 42)
        XCTAssertEqual(roundtripDict?.get(key: "count"), 42)
        XCTAssertEqual(originalDict?.get(key: "active"), true)
        XCTAssertEqual(roundtripDict?.get(key: "active"), true)
        XCTAssertEqual(originalDict?.getArray(key: "tags"), ["a", "b"])
        XCTAssertEqual(roundtripDict?.getArray(key: "tags"), ["a", "b"])
    }

    // MARK: - Edge Cases

    func test_serialize_string_with_special_characters() throws {
        let item = DataItem(value: "hello \"world\" \n\t")
        let serialized = try item.serialize()
        // Verify it can be parsed back
        let parsed = try DataItem(jsonString: serialized)
        XCTAssertEqual(parsed.get(), "hello \"world\" \n\t")
    }

    func test_serialize_empty_array() throws {
        let item = DataItem(value: [])
        XCTAssertEqual(try item.serialize(), "[]")
    }

    func test_serialize_empty_dictionary() throws {
        let item = DataItem(value: [:])
        XCTAssertEqual(try item.serialize(), "{}")
    }

    func test_init_with_whitespace_json_string() throws {
        let item = try DataItem(jsonString: "  42  ")
        XCTAssertEqual(item.get(), 42)
    }

    func test_init_with_unicode_string() throws {
        let item = try DataItem(jsonString: "\"Hello 世界 🌍\"")
        XCTAssertEqual(item.get(), "Hello 世界 🌍")
    }

    func test_serialize_unicode_string() throws {
        let item = DataItem(value: "Hello 世界 🌍")
        let serialized = try item.serialize()
        let parsed = try DataItem(jsonString: serialized)
        XCTAssertEqual(parsed.get(), "Hello 世界 🌍")
    }
}
