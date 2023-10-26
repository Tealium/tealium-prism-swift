//
//  TealiumDataInputTests.swift
//  tealium-swift_Tests
//
//  Created by Tyler Rister on 22/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class TealiumDataInputTests: XCTestCase {

    func test_nsnumber_to_string() {
        let int: TealiumDataInput = NSNumber(2)
        let double: TealiumDataInput = NSNumber(2.5)
        let zero: TealiumDataInput = NSNumber(0)
        let intDouble: TealiumDataInput = NSNumber(2.0)
        let bool: TealiumDataInput = NSNumber(true)
        XCTAssertEqual(try? int.serialize(), "2")
        XCTAssertEqual(try? double.serialize(), "2.5")
        XCTAssertEqual(try? zero.serialize(), "0")
        XCTAssertEqual(try? intDouble.serialize(), "2")
        XCTAssertEqual(try? bool.serialize(), "true")
    }

    func test_double_to_string() {
        let intDouble: TealiumDataInput = 2.0
        let regularDouble: TealiumDataInput = 2.5
        let zero: TealiumDataInput = 0.0
        let negativeDouble: TealiumDataInput = -2.5
        XCTAssertEqual(try? intDouble.serialize(), "2")
        XCTAssertEqual(try? regularDouble.serialize(), "2.5")
        XCTAssertEqual(try? zero.serialize(), "0")
        XCTAssertEqual(try? negativeDouble.serialize(), "-2.5")
    }

    func test_int_to_string() {
        let regularInt: TealiumDataInput = 1
        let maxInt: TealiumDataInput = Int.max
        let minInt: TealiumDataInput = Int.min
        let negativeInt: TealiumDataInput = -5
        let zeroInt: TealiumDataInput = Int.zero
        XCTAssertEqual(try? regularInt.serialize(), "1")
        XCTAssertEqual(try? maxInt.serialize(), "9223372036854775807")
        XCTAssertEqual(try? minInt.serialize(), "-9223372036854775808")
        XCTAssertEqual(try? negativeInt.serialize(), "-5")
        XCTAssertEqual(try? zeroInt.serialize(), "0")
    }

    func test_string_to_string() {
        let string: TealiumDataInput = "test"
        XCTAssertEqual(try? string.serialize(), "\"test\"")
    }

    func test_bool_to_string() {
        let trueBool: TealiumDataInput = true
        let falseBool: TealiumDataInput = false
        XCTAssertEqual(try? trueBool.serialize(), "true")
        XCTAssertEqual(try? falseBool.serialize(), "false")
    }

    func test_array_to_string_and_back() {
        let stringArray: TealiumDataInput = ["test1", "test2", "test3"]
        let mixedArray: TealiumDataInput = ["test1", 1, 2.2, false]
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
        let testDictionary: TealiumDataInput = [
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
//        XCTAssertEqual(try? "2.0".deserialize() as? Double, 2.0) // fails as it's read as int
    }

    func test_non_conforming_types() {
        let nanDouble: TealiumDataInput = Double.nan
        let infinityDouble: TealiumDataInput = Double.infinity
        let serializedNan = try? nanDouble.serialize()
        let serializedInfinity = try? infinityDouble.serialize()
        XCTAssertNotNil(serializedNan)
        XCTAssertNotNil(serializedInfinity)
        let deserializedNan = try? serializedNan?.deserialize()
        let deserializedInfinity = try? serializedInfinity?.deserialize()
        XCTAssertTrueOptional((deserializedNan as? Double)?.isNaN)
        XCTAssertEqual(deserializedInfinity as? Double, Double.infinity)
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

    func test_nsnumber_back_to_type() {
        let int: String = "1"
        let bool: String = "true"
        let double: String = "2.5"
        let intDouble: String = "2.0"
        let zeroInt: String = "0"
        XCTAssertEqual(try? int.deserialize() as? NSNumber, 1)
        XCTAssertEqual(try? bool.deserialize() as? NSNumber, true)
        XCTAssertEqual(try? double.deserialize() as? NSNumber, 2.5)
        XCTAssertEqual(try? intDouble.deserialize() as? NSNumber, 2.0)
        XCTAssertEqual(try? zeroInt.deserialize() as? NSNumber, 0)
    }
}
