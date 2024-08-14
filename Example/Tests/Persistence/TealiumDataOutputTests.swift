//
//  TealiumDataOutputTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 12/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumDataOutputTests: XCTestCase {

    func test_double_can_be_read_as_double() {
        let output = TealiumDataOutput(value: Double(12.345))
        let roundOutput = TealiumDataOutput(value: Double(2.0))
        XCTAssertEqual(output.getDouble(), Double(12.345))
        XCTAssertEqual(roundOutput.getDouble(), Double(2.0))
    }

    func test_float_can_be_read_as_double() {
        let output = TealiumDataOutput(value: Float(12.345))
        let roundOutput = TealiumDataOutput(value: Float(2.0))
        guard let doubleOutput = output.getDouble() else {
            XCTFail("Float(12.345 can't be read as double")
            return
        }
        XCTAssertEqual(doubleOutput, Double(12.345), accuracy: Double(0.001))
        XCTAssertEqual(roundOutput.getDouble(), Double(2.0))
    }

    func test_int_can_be_read_as_double() {
        let output = TealiumDataOutput(value: 12)
        XCTAssertEqual(output.getDouble(), Double(12))
    }

    func test_bool_can_be_read_as_double() {
        let trueOutput = TealiumDataOutput(value: true)
        let falseOutput = TealiumDataOutput(value: false)
        XCTAssertEqual(trueOutput.getDouble(), Double(1))
        XCTAssertEqual(falseOutput.getDouble(), Double(0))
    }

    func test_int_can_be_read_as_int() {
        let output = TealiumDataOutput(value: 12)
        XCTAssertEqual(output.getInt(), 12)
    }

    func test_double_can_be_read_as_int() {
        let output = TealiumDataOutput(value: Double(12.945))
        XCTAssertEqual(output.getInt(), 12)
    }

    func test_float_can_be_read_as_int() {
        let output = TealiumDataOutput(value: Float(12.945))
        XCTAssertEqual(output.getInt(), 12)
    }

    func test_bool_can_be_read_as_int() {
        let trueOutput = TealiumDataOutput(value: true)
        let falseOutput = TealiumDataOutput(value: false)
        XCTAssertEqual(trueOutput.getDouble(), 1)
        XCTAssertEqual(falseOutput.getDouble(), 0)
    }

    func test_int_can_be_read_as_bool() {
        let trueOutput = TealiumDataOutput(value: 1)
        let falseOutput = TealiumDataOutput(value: 0)
        XCTAssertEqual(trueOutput.getBool(), true)
        XCTAssertEqual(falseOutput.getBool(), false)
    }

    func test_double_can_be_read_as_bool() {
        let trueOutput = TealiumDataOutput(value: Double(1.0))
        let falseOutput = TealiumDataOutput(value: Double(0))
        XCTAssertEqual(trueOutput.getBool(), true)
        XCTAssertEqual(falseOutput.getBool(), false)
    }

    func test_float_can_be_read_as_bool() {
        let trueOutput = TealiumDataOutput(value: Float(1))
        let falseOutput = TealiumDataOutput(value: Float(0))
        XCTAssertEqual(trueOutput.getBool(), true)
        XCTAssertEqual(falseOutput.getBool(), false)
    }

    func test_bool_can_be_read_as_bool() {
        let trueOutput = TealiumDataOutput(value: true)
        let falseOutput = TealiumDataOutput(value: false)
        XCTAssertEqual(trueOutput.getBool(), true)
        XCTAssertEqual(falseOutput.getBool(), false)
    }

    func test_any_number_is_an_nsnumber() {
        let int = TealiumDataOutput(value: 1)
        let bool = TealiumDataOutput(value: true)
        let double = TealiumDataOutput(value: Double(3.7))
        let float = TealiumDataOutput(value: Double(2.0))
        XCTAssertNotNil(int.getNSNumber())
        XCTAssertNotNil(bool.getNSNumber())
        XCTAssertNotNil(double.getNSNumber())
        XCTAssertNotNil(float.getNSNumber())
    }

    func test_string_is_read_as_string() {
        let output = TealiumDataOutput(value: "test")
        XCTAssertEqual(output.getString(), "test")
    }

    func test_array_can_read_typed_items() {
        let output = TealiumDataOutput(value: [
            false,
            1,
            Double(2.0),
            Float(3.0),
            "test"
        ] as [Any])
        let array = output.getArray()
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.getBool(index: 0), false)
        XCTAssertEqual(array?.getInt(index: 1), 1)
        XCTAssertEqual(array?.getDouble(index: 2), Double(2.0))
        XCTAssertEqual(array?.getDouble(index: 3), Double(3.0))
        XCTAssertEqual(array?.getString(index: 4), "test")
    }

    func test_dictionary_can_read_typed_items() {
        let output = TealiumDataOutput(value: [
            "bool": false,
            "int": 1,
            "double": Double(2.0),
            "float": Float(3.0),
            "string": "test"
        ] as [String: Any])
        let dictionary = output.getDictionary()
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(dictionary?.getBool(key: "bool"), false)
        XCTAssertEqual(dictionary?.getInt(key: "int"), 1)
        XCTAssertEqual(dictionary?.getDouble(key: "double"), Double(2.0))
        XCTAssertEqual(dictionary?.getDouble(key: "float"), Double(3.0))
        XCTAssertEqual(dictionary?.getString(key: "string"), "test")
    }

    func test_nested_array_can_be_read() {
        let output = TealiumDataOutput(value: [
            ["Nested Key"]
        ])
        let array = output.getArray()
        XCTAssertNotNil(array)
        let nestedArray = array?.getArray(index: 0)
        XCTAssertNotNil(nestedArray)
        XCTAssertEqual(nestedArray?.getString(index: 0), "Nested Key")
    }

    func test_nested_dictionary_can_be_read() {
        let output = TealiumDataOutput(value: [
            ["key": "Nested Key"]
        ])
        let array = output.getArray()
        XCTAssertNotNil(array)
        let nestedArray = array?.getDictionary(index: 0)
        XCTAssertNotNil(nestedArray)
        XCTAssertEqual(nestedArray?.getString(key: "key"), "Nested Key")
    }

    func test_getDataInput_from_value_can_be_read_as_TealiumDataInput() {
        let int = TealiumDataOutput(value: 1)
        let double = TealiumDataOutput(value: 1.4)
        let intDouble = TealiumDataOutput(value: 2.0)
        let bool = TealiumDataOutput(value: true)
        let string = TealiumDataOutput(value: "string")
        let array = TealiumDataOutput(value: [1, 2, 3.5])
        let dictionary = TealiumDataOutput(value: ["1": 1, "2": 2, "3": 3.5])
        let multiLevelDictionary = TealiumDataOutput(value: ["1": [1, "1"], "2": [2, "2"], "3": [3.5, "3.5"]])
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
}
