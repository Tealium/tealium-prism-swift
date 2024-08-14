//
//  TealiumDataOutputFromStringTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 13/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//
@testable import TealiumSwift
import XCTest

final class TealiumDataOutputFromStringTests: XCTestCase {

    func test_double_from_stringValue_can_be_read_as_double() {
        let output = TealiumDataOutput(stringValue: "12.345")
        let roundOutput = TealiumDataOutput(stringValue: "2.0")
        XCTAssertEqual(output.getDouble(), Double(12.345))
        XCTAssertEqual(roundOutput.getDouble(), Double(2.0))
    }

    func test_int_from_stringValue_can_be_read_as_double() {
        let output = TealiumDataOutput(stringValue: "12")
        XCTAssertEqual(output.getDouble(), Double(12))
    }

    func test_bool_from_stringValue_can_be_read_as_double() {
        let trueOutput = TealiumDataOutput(stringValue: "true")
        let falseOutput = TealiumDataOutput(stringValue: "false")
        XCTAssertEqual(trueOutput.getDouble(), Double(1))
        XCTAssertEqual(falseOutput.getDouble(), Double(0))
    }

    func test_int_from_stringValue_can_be_read_as_int() {
        let output = TealiumDataOutput(stringValue: "12")
        XCTAssertEqual(output.getInt(), 12)
    }

    func test_double_from_stringValue_can_be_read_as_int() {
        let output = TealiumDataOutput(stringValue: "12.945")
        XCTAssertEqual(output.getInt(), 12)
    }

    func test_bool_from_stringValue_can_be_read_as_int() {
        let trueOutput = TealiumDataOutput(stringValue: "true")
        let falseOutput = TealiumDataOutput(stringValue: "false")
        XCTAssertEqual(trueOutput.getDouble(), 1)
        XCTAssertEqual(falseOutput.getDouble(), 0)
    }

    func test_int_from_stringValue_can_be_read_as_bool() {
        let trueOutput = TealiumDataOutput(stringValue: "1")
        let falseOutput = TealiumDataOutput(stringValue: "0")
        XCTAssertEqual(trueOutput.getBool(), true)
        XCTAssertEqual(falseOutput.getBool(), false)
    }

    func test_double_from_stringValue_can_be_read_as_bool() {
        let trueOutput = TealiumDataOutput(stringValue: "1.0")
        let falseOutput = TealiumDataOutput(stringValue: "0")
        XCTAssertEqual(trueOutput.getBool(), true)
        XCTAssertEqual(falseOutput.getBool(), false)
    }

    func test_bool_from_stringValue_can_be_read_as_bool() {
        let trueOutput = TealiumDataOutput(stringValue: "true")
        let falseOutput = TealiumDataOutput(stringValue: "false")
        XCTAssertEqual(trueOutput.getBool(), true)
        XCTAssertEqual(falseOutput.getBool(), false)
    }

    func test_any_number_from_stringValue_is_an_nsnumber() {
        let int = TealiumDataOutput(stringValue: "1")
        let bool = TealiumDataOutput(stringValue: "true")
        let double = TealiumDataOutput(stringValue: "3.7")
        let float = TealiumDataOutput(stringValue: "2.0")
        XCTAssertNotNil(int.getNSNumber())
        XCTAssertNotNil(bool.getNSNumber())
        XCTAssertNotNil(double.getNSNumber())
        XCTAssertNotNil(float.getNSNumber())
    }

    func test_stringValue_from_stringValue_is_read_as_string() {
        let output = TealiumDataOutput(stringValue: "\"test\"")
        XCTAssertEqual(output.getString(), "test")
    }

    func test_getDataInput_from_stringValue_can_be_read_as_TealiumDataInput() {
        let int = TealiumDataOutput(stringValue: "1")
        let double = TealiumDataOutput(stringValue: "1.4")
        let intDouble = TealiumDataOutput(stringValue: "2.0")
        let bool = TealiumDataOutput(stringValue: "true")
        let string = TealiumDataOutput(stringValue: "\"string\"")
        let array = TealiumDataOutput(stringValue: "[\"1\",2,\"3.5\"]")
        let dictionary = TealiumDataOutput(stringValue: "{\"1\":1,\"2\":2,\"3\":3.5}")
        let multiLevelDictionary = TealiumDataOutput(stringValue: "{\"1\":[1,\"1\"],\"2\":[2,\"2\"],\"3\":[3.5,\"3.5\"]}")
        XCTAssertNotNil(int.getDataInput())
        XCTAssertNotNil(int.getDataInput())
        XCTAssertNotNil(double.getDataInput())
        XCTAssertNotNil(intDouble.getDataInput())
        XCTAssertNotNil(bool.getDataInput())
        XCTAssertNotNil(string.getDataInput())
        XCTAssertNotNil(array.getDataInput())
        XCTAssertNotNil(dictionary.getDataInput())
        let mlDictionaryInput = multiLevelDictionary.getDataInput()
        XCTAssertNotNil(mlDictionaryInput)
        let tealiumDictionary = mlDictionaryInput as? TealiumDictionaryInput
        let array1 = tealiumDictionary?["1"] as? [TealiumDataInput]
        XCTAssertNotNil(array1)
        XCTAssertEqual(array1?[0] as? Int, 1)
        XCTAssertEqual(array1?[1] as? String, "1")
        let array2 = tealiumDictionary?["2"] as? [TealiumDataInput]
        XCTAssertNotNil(array2)
        XCTAssertEqual(array2?[0] as? Int, 2)
        XCTAssertEqual(array2?[1] as? String, "2")
        let array3 = tealiumDictionary?["3"] as? [TealiumDataInput]
        XCTAssertNotNil(array3)
        XCTAssertEqual(array3?[0] as? Double, 3.5)
        XCTAssertEqual(array3?[1] as? String, "3.5")
    }

    func test_getDataInput_from_rounded_double_stringValue_can_only_be_cast_to_int() {
        // This is a limitation because the saved number is interpreted as an Int when read.
        // Use getDouble instead if you want to make sure to read the value as you want.
        let roundedDouble = TealiumDataOutput(stringValue: "3.0")
        XCTAssertNil(roundedDouble.getDataInput() as? Double)
        XCTAssertNil(roundedDouble.getDataInput() as? Float)
        XCTAssertNotNil(roundedDouble.getDataInput() as? Int)
    }
}
