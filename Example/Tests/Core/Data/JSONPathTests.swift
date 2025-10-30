//
//  JSONPathTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class JSONPathTests: XCTestCase {
    let array: [DataItem] = [
        DataItem(converting: [
            "object": [
                "abc": "value",
                "àϴڈ": "different language",
                "reserved.char": "other",
                "special@char": "third",
                "[\"somequote\"]": "quoted",
                "\"both'quotes\"": "both",
                "esca\\ping": "escaped"
            ]
        ])
    ]
    let obj: DataObject = [
        "array": [
            [
                "abc": "value",
                "àϴڈ": "different language",
                "reserved.char": "other",
                "special@char": "third",
                "[\"somequote\"]": "quoted",
                "\"both'quotes\"": "both",
                "esca\\ping": "escaped"
            ]
        ]
    ]

    func test_basic_object_path() {
        let path = JSONPath["array"][0]["abc"]
        XCTAssertEqual(path.render(), "array[0].abc")
        XCTAssertEqual(obj.extract(path: path), "value")
    }

    func test_basic_object_path_with_different_language() {
        let path = JSONPath["array"][0]["àϴڈ"]
        XCTAssertEqual(path.render(), "array[0].àϴڈ")
        XCTAssertEqual(obj.extract(path: path), "different language")
    }

    func test_basic_object_path_ending_with_array() {
        let path = JSONPath["array"][0]
        XCTAssertEqual(path.render(), "array[0]")
        XCTAssertEqual(obj.extractDictionary(path: path, of: String.self), [
            "abc": "value",
            "àϴڈ": "different language",
            "reserved.char": "other",
            "special@char": "third",
            "[\"somequote\"]": "quoted",
            "\"both'quotes\"": "both",
            "esca\\ping": "escaped"
        ])
    }

    func test_object_path_with_reserved_character() {
        let path = JSONPath["array"][0]["reserved.char"]
        XCTAssertEqual(path.render(), "array[0][\"reserved.char\"]")
        XCTAssertEqual(obj.extract(path: path), "other")
    }

    func test_object_path_with_special_character() {
        let path = JSONPath["array"][0]["special@char"]
        XCTAssertEqual(path.render(), "array[0][\"special@char\"]")
        XCTAssertEqual(obj.extract(path: path), "third")
    }

    func test_object_path_with_quote_uses_single_quote() {
        let path = JSONPath["array"][0]["[\"somequote\"]"]
        XCTAssertEqual(path.render(), "array[0]['[\"somequote\"]']")
        XCTAssertEqual(obj.extract(path: path), "quoted")
    }

    func test_object_path_with_both_quotes_escapes_double_quote() {
        let path = JSONPath["array"][0]["\"both'quotes\""]
        XCTAssertEqual(path.render(), "array[0][\"\\\"both'quotes\\\"\"]")
        XCTAssertEqual(obj.extract(path: path), "both")
    }

    func test_object_path_with_escape_double_escapes_it_to_keep_it() {
        let path = JSONPath["array"][0]["esca\\ping"]
        XCTAssertEqual(path.render(), "array[0][\"esca\\\\ping\"]")
        XCTAssertEqual(obj.extract(path: path), "escaped")
    }

    func test_basic_array_path() {
        let path = JSONPath[0]["object"]["abc"]
        XCTAssertEqual(path.render(), "[0].object.abc")
        XCTAssertEqual(array.extract(path: path), "value")
    }

    func test_basic_array_path_ending_with_object() {
        let path = JSONPath[0]["object"]
        XCTAssertEqual(path.render(), "[0].object")
        XCTAssertEqual(array.extractDictionary(path: path, of: String.self), [
            "abc": "value",
            "àϴڈ": "different language",
            "reserved.char": "other",
            "special@char": "third",
            "[\"somequote\"]": "quoted",
            "\"both'quotes\"": "both",
            "esca\\ping": "escaped"
        ])
    }

    func test_array_path_with_reserved_character() {
        let path = JSONPath[0]["object"]["reserved.char"]
        XCTAssertEqual(path.render(), "[0].object[\"reserved.char\"]")
        XCTAssertEqual(array.extract(path: path), "other")
    }

    func test_array_path_with_special_character() {
        let path = JSONPath[0]["object"]["special@char"]
        XCTAssertEqual(path.render(), "[0].object[\"special@char\"]")
        XCTAssertEqual(array.extract(path: path), "third")
    }

    func test_array_path_with_quotes_uses_single_quote() {
        let path = JSONPath[0]["object"]["[\"somequote\"]"]
        XCTAssertEqual(path.render(), "[0].object['[\"somequote\"]']")
        XCTAssertEqual(array.extract(path: path), "quoted")
    }

    func test_array_path_with_escape_double_escapes_it_to_keep_it() {
        let path = JSONPath[0]["object"]["esca\\ping"]
        XCTAssertEqual(path.render(), "[0].object[\"esca\\\\ping\"]")
        XCTAssertEqual(array.extract(path: path), "escaped")
    }

    func test_array_path_with_both_quotes_escapes_double_quote() {
        let path = JSONPath[0]["object"]["\"both'quotes\""]
        XCTAssertEqual(path.render(), "[0].object[\"\\\"both'quotes\\\"\"]")
        XCTAssertEqual(array.extract(path: path), "both")
    }

    func test_subscript_does_not_mutate_base_path() {
        let basePath = JSONPath["start"]
        let first = basePath["first"]
        let second = basePath["second"]
        XCTAssertEqual(first, JSONPath["start"]["first"])
        XCTAssertEqual(second, JSONPath["start"]["second"])
    }
}
