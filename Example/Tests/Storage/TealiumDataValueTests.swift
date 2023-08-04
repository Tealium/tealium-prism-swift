//
//  TealiumDataValueTests.swift
//  tealium-swift_Tests
//
//  Created by Tyler Rister on 22/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class TealiumDataValueTests: XCTestCase {

    func test_double_to_string() {
        let intDouble: TealiumDataValue = 2.0
        let regularDouble: TealiumDataValue = 2.5
        let zero: TealiumDataValue = 0.0
        let negativeDouble: TealiumDataValue = -2.5
        XCTAssertEqual(try? intDouble.serialize(), "2")
        XCTAssertEqual(try? regularDouble.serialize(), "2.5")
        XCTAssertEqual(try? zero.serialize(), "0")
        XCTAssertEqual(try? negativeDouble.serialize(), "-2.5")
    }

    func test_int_to_string() {
        let regularInt: TealiumDataValue = 1
        let maxInt: TealiumDataValue = Int.max
        let minInt: TealiumDataValue = Int.min
        let negativeInt: TealiumDataValue = -5
        let zeroInt: TealiumDataValue = Int.zero
        XCTAssertEqual(try? regularInt.serialize(), "1")
        XCTAssertEqual(try? maxInt.serialize(), "9223372036854775807")
        XCTAssertEqual(try? minInt.serialize(), "-9223372036854775808")
        XCTAssertEqual(try? negativeInt.serialize(), "-5")
        XCTAssertEqual(try? zeroInt.serialize(), "0")
    }

    func test_string_to_string() {
        let string: TealiumDataValue = "test"
        XCTAssertEqual(try? string.serialize(), "\"test\"")
    }

    func test_bool_to_string() {
        let trueBool: TealiumDataValue = true
        let falseBool: TealiumDataValue = false
        XCTAssertEqual(try? trueBool.serialize(), "true")
        XCTAssertEqual(try? falseBool.serialize(), "false")
    }

    func test_array_to_string_and_back() {
        let stringArray: TealiumDataValue = ["test1", "test2", "test3"]
        let mixedArray: TealiumDataValue = ["test1", 1, 2.2, false]
        let stringArrayBack = try? stringArray.serialize().deserialize() as? [Any]
        let mixedArrayBack = try? mixedArray.serialize().deserialize() as? [Any]
        XCTAssertEqual(stringArrayBack?[0] as? String, "test1")
        XCTAssertEqual(stringArrayBack?[1] as? String, "test2")
        XCTAssertEqual(stringArrayBack?[2] as? String, "test3")
        XCTAssertEqual(mixedArrayBack?[0] as? String, "test1")
        XCTAssertEqual(mixedArrayBack?[1] as? Int, 1)
        XCTAssertEqual(mixedArrayBack?[2] as? Double, 2.2)
        XCTAssertEqual(mixedArrayBack?[3] as? Bool, false)
    }

    func test_dictionary_to_string_and_back() {
        let testDictionary: TealiumDataValue = [
            "string_key": "test_string",
            "int_key": 4,
            "double_key": 2.6,
            "bool_key": true,
            "string_array_key": ["string1", "string2"],
            "mixed_array_key": ["mixed_string1", 8, false],
            "dictionary_key": [
                "sub_key1": "sub_string",
                "sub_key2": true,
                "sub_key3": 4,
                "sub_array": ["test_string1", "test_string2"]
            ]
        ]
        let dictionaryBack = try? testDictionary.serialize().deserialize() as? [String: Any]
        XCTAssertEqual(dictionaryBack?["string_key"] as? String, "test_string")
        XCTAssertEqual(dictionaryBack?["int_key"] as? Int, 4)
        XCTAssertEqual(dictionaryBack?["double_key"] as? Double, 2.6)
        XCTAssertEqual(dictionaryBack?["bool_key"] as? Bool, true)
        XCTAssertEqual((dictionaryBack?["string_array_key"] as? [String])?[0], "string1")
        XCTAssertEqual((dictionaryBack?["string_array_key"] as? [String])?[1], "string2")
        let mixedArray = dictionaryBack?["mixed_array_key"] as? [Any]
        XCTAssertEqual(mixedArray?[0] as? String, "mixed_string1")
        XCTAssertEqual(mixedArray?[1] as? Int, 8)
        XCTAssertEqual(mixedArray?[2] as? Bool, false)
        let subDictionary = dictionaryBack?["dictionary_key"] as? [String: Any]
        XCTAssertEqual(subDictionary?["sub_key1"] as? String, "sub_string")
        XCTAssertEqual(subDictionary?["sub_key2"] as? Bool, true)
        XCTAssertEqual(subDictionary?["sub_key3"] as? Int, 4)
        let subDictionaryArray = subDictionary?["sub_array"] as? [String]
        XCTAssertEqual(subDictionaryArray?[0], "test_string1")
        XCTAssertEqual(subDictionaryArray?[1], "test_string2")
    }

    func test_double_back_to_type() {
        let regularDouble: String = "2.5"
        let negativeDouble: String = "-2.5"
        XCTAssertEqual(try? regularDouble.deserialize() as? Double, 2.5)
        XCTAssertEqual(try? negativeDouble.deserialize() as? Double, -2.5)
    }

    func test_non_conforming_types() {
        let nanDouble: TealiumDataValue = Double.nan
        let infinityDouble: TealiumDataValue = Double.infinity
        let containsNil: TealiumDictionaryOptionals = ["test_key_1": nil]
        let serializedNan = try? nanDouble.serialize()
        let serializedInfinity = try? infinityDouble.serialize()
        let serializedWithNil = try? containsNil.serialize()
        XCTAssertNotNil(serializedNan)
        XCTAssertNotNil(serializedInfinity)
        XCTAssertNotNil(serializedWithNil)
        let deserializedNan = try? serializedNan?.deserialize()
        let deserializedInfinity = try? serializedInfinity?.deserialize()
        let deserializedContainsNil = try? serializedWithNil?.deserialize() as? [String: Any?]
        XCTAssertTrueOptional((deserializedNan as? Double)?.isNaN)
        XCTAssertEqual(deserializedInfinity as? Double, Double.infinity)
        XCTAssertTrueOptional(deserializedContainsNil?.keys.contains("test_key_1"))
        XCTAssertEqual(deserializedContainsNil?["test_key_1"] as? NSNull, NSNull())
    }

    func test_int_back_to_type() {
        let regularInt: String = "1"
        let maxInt: String = "9223372036854775807"
        let minInt: String = "-9223372036854775808"
        let negativeInt: String = "-5"
        let zeroInt: String = "0"
        XCTAssertEqual(try? regularInt.deserialize() as? Int, 1)
        XCTAssertEqual(try? maxInt.deserialize() as? Int, .max)
        XCTAssertEqual(try? minInt.deserialize() as? Int, .min)
        XCTAssertEqual(try? negativeInt.deserialize() as? Int, -5)
        XCTAssertEqual(try? zeroInt.deserialize() as? Int, .zero)
    }

    func test_string_back_to_type() {
        let string: String = "\"test\""
        XCTAssertEqual(try? string.deserialize() as? String, "test")
    }

    func test_bool_back_to_type() {
        let trueBool: String = "true"
        let falseBool: String = "false"
        XCTAssertEqual(try? trueBool.deserialize() as? Bool, true)
        XCTAssertEqual(try? falseBool.deserialize() as? Bool, false)
    }
}
