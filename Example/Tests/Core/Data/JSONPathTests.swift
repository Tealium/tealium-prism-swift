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
                "reserved.char": "other",
                "special@char": "third",
            ]
        ])
    ]
    let obj: DataObject = [
        "array": [
            [
                "abc": "value",
                "reserved.char": "other",
                "special@char": "third",
            ]
        ]
    ]

    func test_basic_object_path() {
        let path = JSONPath["array"][0]["abc"]
        XCTAssertEqual("\(path)", "array[0].abc")
        XCTAssertEqual(obj.extract(path: path), "value")
    }

    func test_basic_object_path_ending_with_array() {
        let path = JSONPath["array"][0]
        XCTAssertEqual("\(path)", "array[0]")
        XCTAssertEqual(obj.extractDictionary(path: path, of: String.self), [
            "abc": "value",
            "reserved.char": "other",
            "special@char": "third"
        ])
    }

    func test_object_path_with_reserved_character() {
        let path = JSONPath["array"][0]["reserved.char"]
        XCTAssertEqual("\(path)", "array[0][\"reserved.char\"]")
        XCTAssertEqual(obj.extract(path: path), "other")
    }

    func test_object_path_with_special_character() {
        let path = JSONPath["array"][0]["special@char"]
        XCTAssertEqual("\(path)", "array[0][\"special@char\"]")
        XCTAssertEqual(obj.extract(path: path), "third")
    }

    func test_basic_array_path() {
        let path = JSONPath[0]["object"]["abc"]
        XCTAssertEqual("\(path)", "[0].object.abc")
        XCTAssertEqual(array.extract(path: path), "value")
    }

    func test_basic_array_path_ending_with_object() {
        let path = JSONPath[0]["object"]
        XCTAssertEqual("\(path)", "[0].object")
        XCTAssertEqual(array.extractDictionary(path: path, of: String.self), [
            "abc": "value",
            "reserved.char": "other",
            "special@char": "third"
        ])
    }

    func test_array_path_with_reserved_character() {
        let path = JSONPath[0]["object"]["reserved.char"]
        XCTAssertEqual("\(path)", "[0].object[\"reserved.char\"]")
        XCTAssertEqual(array.extract(path: path), "other")
    }

    func test_array_path_with_special_character() {
        let path = JSONPath[0]["object"]["special@char"]
        XCTAssertEqual("\(path)", "[0].object[\"special@char\"]")
        XCTAssertEqual(array.extract(path: path), "third")
    }
}
