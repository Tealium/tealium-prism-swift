//
//  DataItem+SerializingTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 30/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class DataItemSerializingTests: XCTestCase {
    let nilObj: Any? = nil
    func getNil() -> Any {
        nilObj as Any
    }
    var any: Any = NSNull()

    func getValue() throws -> DataItem {
        try DataItem(serializing: any)
    }

    func test_nil_throws_an_error() throws {
        any = getNil()
        XCTAssertNotNSNull(any)
        XCTAssertThrowsError(try getValue())
    }

    func test_array_with_nil_replaces_it_with_NSNull() throws {
        any = [1, 2, 3, nil, 4]
        XCTAssertNSNull(try getValue().getDataArray()?[3].toDataInput())
    }

    func test_dictionary_with_nil_replaces_it_with_NSNull() throws {
        any = ["1": 1, "2": 2, "3": 3, "nil": nil, "4": 4]
        XCTAssertNSNull(try getValue().getDataDictionary()?["nil"]?.toDataInput())
    }

    func test_nested_dictionary_with_nil_replaces_it_with_NSNull() throws {
        any = ["1": 1, "2": 2, "3": 3, "nil": nil, "4": ["inner1": 1, "inner2": nil]]
        let value = try getValue()
        XCTAssertNSNull(value.getDataDictionary()?["nil"]?.toDataInput())
        XCTAssertNSNull(value.getDataDictionary()?.getDataDictionary(key: "4")?["inner2"]?.toDataInput())
    }

    func test_non_convertible_throws_an_error() {
        any = NSObject()
        XCTAssertThrowsError(try getValue())
    }

    func test_array_with_non_convertible_throws_an_error() {
        any = [1, 2, 3, NSObject(), 4]
        XCTAssertThrowsError(try getValue())
    }

    func test_dictionary_with_non_convertible_throws_an_error() {
        any = ["1": 1, "2": 2, "3": 3, "nil": NSObject(), "4": 4]
        XCTAssertThrowsError(try getValue())
    }

    func test_nested_dictionary_with_non_convertible_throws_an_error() {
        any = ["1": 1, "2": 2, "3": 3, "nil": NSObject(), "4": ["inner1": 1, "inner2": NSObject()]]
        XCTAssertThrowsError(try getValue())
    }

    func test_complex_nested_type_is_converted_properly() throws {
        any = [
            "1": 1,
            "2": [
                22,
                "22",
                true,
                3.5,
                3.0,
                Double(4.0),
                Double(3.7),
                nil,
                ["222": nil]
            ],
            "3": [
                "33": [
                    333,
                    "333",
                    [nil, "3333"]
                ]
            ]
        ]
        let expected: [String: Any] = [
            "1": 1,
            "2": [
                22,
                "22",
                true,
                3.5,
                3.0,
                Double(4.0),
                Double(3.7),
                NSNull(),
                ["222": NSNull()]],
            "3": [
                "33": [
                    333,
                    "333",
                    [NSNull(), "3333"]
                ]
            ]
        ]
        XCTAssertEqual(try getValue().toDataInput() as? [String: Any], expected)
    }

    func test_encodable_object_is_parsed_as_a_dictionary() throws {
        any = SomeCodable(someString: "str", someInt: 1, someDouble: 2.5)
        XCTAssertEqual(try getValue().toDataInput() as? [String: Any], ["someString": "str", "someInt": 1, "someDouble": 2.5])
    }

    func test_dictionary_with_encodable_objects_is_parsed_as_a_dictionary() throws {
        any = ["key": SomeCodable(someString: "str", someInt: 1, someDouble: 2.5)]
        XCTAssertEqual(try getValue().toDataInput() as? [String: [String: Any]], ["key": ["someString": "str", "someInt": 1, "someDouble": 2.5]])
    }

    func test_empty_encodable_object_is_parsed_as_an_empty_dictionary() throws {
        any = SomeEmptyCodable()
        XCTAssertEqual(try getValue().toDataInput() as? [String: Any], [:])
    }

    func test_single_value_encodable_object_is_parsed_into_that_value() throws {
        any = SomeSingleValueCodable()
        XCTAssertEqual(try getValue().get(), "something")
    }

    struct SomeCodable: Encodable {
        let someString: String
        let someInt: Int
        let someDouble: Double
    }

    struct SomeEmptyCodable: Encodable {}
    struct SomeSingleValueCodable: Encodable {
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode("something")
        }
    }

    func test_nan_and_infinity_are_converted_to_string() throws {
        let value = try DataItem(serializing: [NSNumber(value: Double.nan), NSNumber(value: Float.infinity), NSNumber(value: -Float.infinity), -Double.infinity, Double.infinity, Float.nan])
        let result = value.getArray(of: String.self)
        let nan = "NaN"
        let infinity = "Infinity"
        let negInfinity = "-Infinity"
        XCTAssertEqual(result, [nan, infinity, negInfinity, negInfinity, infinity, nan])
    }

    func test_iso_date_strings_remain_strings() throws {
        let value = try DataItem(serializing: Date())
        let result = value.get(as: String.self)
        XCTAssertNotNil(result)
    }
}
