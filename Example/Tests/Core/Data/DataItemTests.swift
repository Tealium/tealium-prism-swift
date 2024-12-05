//
//  DataItemTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 12/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class DataItemTests: XCTestCase {

    func test_double_can_be_read_as_any_number() {
        let output = DataItem(value: Double(12.5))
        let roundOutput = DataItem(value: Double(2.0))
        XCTAssertEqual(output.get(), Double(12.5))
        XCTAssertEqual(roundOutput.get(), Double(2.0))
        XCTAssertEqual(output.get(), 12)
        XCTAssertEqual(roundOutput.get(), 2)
        XCTAssertEqual(output.get(), Float(12.5))
        XCTAssertEqual(roundOutput.get(), Float(2.0))
        XCTAssertEqual(output.get(), Int64(12))
        XCTAssertEqual(roundOutput.get(), Int64(2))
        XCTAssertEqual(output.get(), NSNumber(12.5))
        XCTAssertEqual(roundOutput.get(), NSNumber(2))
        XCTAssertNil(output.get(as: Bool.self))
        XCTAssertNil(roundOutput.get(as: Bool.self))
        XCTAssertNil(output.get(as: String.self))
        XCTAssertNil(roundOutput.get(as: String.self))
        XCTAssertNil(output.getDataArray())
        XCTAssertNil(roundOutput.getDataArray())
        XCTAssertNil(output.getDataDictionary())
        XCTAssertNil(roundOutput.getDataDictionary())
    }

    func test_float_can_be_read_as_any_number() {
        let output = DataItem(value: Float(12.5))
        let roundOutput = DataItem(value: Float(2.0))
        XCTAssertEqual(output.get(), Double(12.5))
        XCTAssertEqual(roundOutput.get(), Double(2.0))
        XCTAssertEqual(output.get(), 12)
        XCTAssertEqual(roundOutput.get(), 2)
        XCTAssertEqual(output.get(), Float(12.5))
        XCTAssertEqual(roundOutput.get(), Float(2.0))
        XCTAssertEqual(output.get(), Int64(12))
        XCTAssertEqual(roundOutput.get(), Int64(2))
        XCTAssertEqual(output.get(), NSNumber(12.5))
        XCTAssertEqual(roundOutput.get(), NSNumber(2))
        XCTAssertNil(output.get(as: Bool.self))
        XCTAssertNil(roundOutput.get(as: Bool.self))
        XCTAssertNil(output.get(as: String.self))
        XCTAssertNil(roundOutput.get(as: String.self))
        XCTAssertNil(output.getDataArray())
        XCTAssertNil(roundOutput.getDataArray())
        XCTAssertNil(output.getDataDictionary())
        XCTAssertNil(roundOutput.getDataDictionary())
    }

    func test_int_can_be_read_as_any_number() {
        let output = DataItem(value: 12)
        XCTAssertEqual(output.get(), Double(12))
        XCTAssertEqual(output.get(), 12)
        XCTAssertEqual(output.get(), Float(12))
        XCTAssertEqual(output.get(), Int64(12))
        XCTAssertEqual(output.get(), NSNumber(12))
        XCTAssertNil(output.get(as: Bool.self))
        XCTAssertNil(output.get(as: String.self))
        XCTAssertNil(output.getDataArray())
        XCTAssertNil(output.getDataDictionary())
    }

    func test_bool_can_be_read_as_bool() {
        let trueOutput = DataItem(value: true)
        let falseOutput = DataItem(value: false)
        XCTAssertNil(trueOutput.get(as: Double.self))
        XCTAssertNil(falseOutput.get(as: Double.self))
        XCTAssertNil(trueOutput.get(as: Int.self))
        XCTAssertNil(falseOutput.get(as: Int.self))
        XCTAssertNil(trueOutput.get(as: Float.self))
        XCTAssertNil(falseOutput.get(as: Float.self))
        XCTAssertNil(trueOutput.get(as: Int64.self))
        XCTAssertNil(falseOutput.get(as: Int64.self))
        XCTAssertTrueOptional(trueOutput.get(as: Bool.self))
        XCTAssertFalseOptional(falseOutput.get(as: Bool.self))
        XCTAssertEqual(trueOutput.get(), NSNumber(true))
        XCTAssertEqual(falseOutput.get(), NSNumber(false))
        XCTAssertNil(trueOutput.get(as: String.self))
        XCTAssertNil(falseOutput.get(as: String.self))
        XCTAssertNil(trueOutput.getDataArray())
        XCTAssertNil(falseOutput.getDataArray())
        XCTAssertNil(trueOutput.getDataDictionary())
        XCTAssertNil(falseOutput.getDataDictionary())
    }

    func test_string_is_read_as_string() {
        let output = DataItem(value: "test")
        XCTAssertNil(output.get(as: Double.self))
        XCTAssertNil(output.get(as: Int.self))
        XCTAssertNil(output.get(as: Float.self))
        XCTAssertNil(output.get(as: Int64.self))
        XCTAssertNil(output.get(as: NSNumber.self))
        XCTAssertNil(output.get(as: Bool.self))
        XCTAssertEqual(output.get(), "test")
        XCTAssertNil(output.getDataArray())
        XCTAssertNil(output.getDataDictionary())
    }

    func test_array_can_read_typed_items() {
        let output = DataItem(value: [false, 1, Double(2.0), Float(3.0), "test"])
        let array = output.getDataArray()
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.get(index: 0), false)
        XCTAssertEqual(array?.get(index: 1), 1)
        XCTAssertEqual(array?.get(index: 2), Double(2.0))
        XCTAssertEqual(array?.get(index: 3), Double(3.0))
        XCTAssertEqual(array?.get(index: 4), "test")
    }

    func test_array_returns_nil_when_out_of_bounds() {
        let output = DataItem(value: [])
        let array = output.getDataArray()
        XCTAssertNotNil(array)
        XCTAssertNil(array?.get(index: 0, as: Int.self))
        XCTAssertNil(array?.get(index: 1, as: Int.self))
        XCTAssertNil(array?.get(index: 2, as: Int.self))
        XCTAssertNil(array?.get(index: 3, as: Int.self))
        XCTAssertNil(array?.get(index: 4, as: Int.self))
    }

    func test_dictionary_can_read_typed_items() {
        let output = DataItem(value: ["bool": false, "int": 1, "double": Double(2.0), "float": Float(3.0), "string": "test"])
        let dictionary = output.getDataDictionary()
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(dictionary?.get(key: "bool"), false)
        XCTAssertEqual(dictionary?.get(key: "int"), 1)
        XCTAssertEqual(dictionary?.get(key: "double"), Double(2.0))
        XCTAssertEqual(dictionary?.get(key: "float"), Double(3.0))
        XCTAssertEqual(dictionary?.get(key: "string"), "test")
    }

    func test_dictionary_returns_nil_on_missing_keys() {
        let output = DataItem(value: [:])
        let dictionary = output.getDataDictionary()
        XCTAssertNotNil(dictionary)
        XCTAssertNil(dictionary?.get(key: "bool", as: Bool.self))
        XCTAssertNil(dictionary?.get(key: "int", as: Int64.self))
        XCTAssertNil(dictionary?.get(key: "double", as: Double.self))
        XCTAssertNil(dictionary?.get(key: "float", as: Double.self))
        XCTAssertNil(dictionary?.get(key: "string", as: String.self))
    }

    func test_nested_array_can_be_read() {
        let output = DataItem(value: [
            ["Nested Key"]
        ])
        let array = output.getDataArray()
        XCTAssertNotNil(array)
        let nestedArray = array?.getDataArray(index: 0)
        XCTAssertNotNil(nestedArray)
        XCTAssertEqual(nestedArray?.get(index: 0), "Nested Key")
    }

    func test_nested_dictionary_can_be_read() {
        let output = DataItem(value: [
            ["key": "Nested Key"]
        ])
        let array = output.getDataArray()
        XCTAssertNotNil(array)
        let nestedArray = array?.getDataDictionary(index: 0)
        XCTAssertNotNil(nestedArray)
        XCTAssertEqual(nestedArray?.get(key: "key"), "Nested Key")
    }

    func test_toDataInput_from_value_can_be_read_as_DataInput() {
        let int = DataItem(value: 1)
        let double = DataItem(value: 1.4)
        let intDouble = DataItem(value: 2.0)
        let bool = DataItem(value: true)
        let string = DataItem(value: "string")
        let array = DataItem(value: [1, 2, 3.5])
        let dictionary = DataItem(value: ["1": 1, "2": 2, "3": 3.5])
        let multiLevelDictionary = DataItem(value: ["1": [1, "1"], "2": [2, "2"], "3": [3.5, "3.5"]])
        XCTAssertNotNil(int.toDataInput())
        XCTAssertNotNil(int.toDataInput())
        XCTAssertNotNil(double.toDataInput())
        XCTAssertNotNil(intDouble.toDataInput())
        XCTAssertNotNil(bool.toDataInput())
        XCTAssertNotNil(string.toDataInput())
        XCTAssertNotNil(array.toDataInput())
        XCTAssertNotNil(dictionary.toDataInput())
        let mlDictionaryInput = multiLevelDictionary.toDataInput()
        XCTAssertNotNil(mlDictionaryInput)
        let tealiumDictionary = mlDictionaryInput as? [String: Any]
        XCTAssertEqual(tealiumDictionary?["1"] as? [DataInput], [1, "1"])
        XCTAssertEqual(tealiumDictionary?["2"] as? [DataInput], [2, "2"])
        XCTAssertEqual(tealiumDictionary?["3"] as? [DataInput], [3.5, "3.5"])
    }

    func test_toDataInput_from_conversion_can_be_read_as_DataInput() throws {
        let int = try DataItem(serializing: 1)
        let double = try DataItem(serializing: 1.4)
        let intDouble = try DataItem(serializing: 2.0)
        let bool = try DataItem(serializing: true)
        let string = try DataItem(serializing: "string")
        let array = try DataItem(serializing: [1, 2, 3.5])
        let dictionary = try DataItem(serializing: ["1": 1, "2": 2, "3": 3.5])
        let multiLevelDictionary = try DataItem(serializing: ["1": [1, "1"], "2": [2, "2"], "3": [3.5, "3.5"]])
        XCTAssertNotNil(int.toDataInput())
        XCTAssertNotNil(int.toDataInput())
        XCTAssertNotNil(double.toDataInput())
        XCTAssertNotNil(intDouble.toDataInput())
        XCTAssertNotNil(bool.toDataInput())
        XCTAssertNotNil(string.toDataInput())
        XCTAssertNotNil(array.toDataInput())
        XCTAssertNotNil(dictionary.toDataInput())
        let mlDictionaryInput = multiLevelDictionary.toDataInput()
        XCTAssertNotNil(mlDictionaryInput)
        let tealiumDictionary = mlDictionaryInput as? [String: Any]
        XCTAssertEqual(tealiumDictionary?["1"] as? [DataInput], [1, "1"])
        XCTAssertEqual(tealiumDictionary?["2"] as? [DataInput], [2, "2"])
        XCTAssertEqual(tealiumDictionary?["3"] as? [DataInput], [3.5, "3.5"])
    }

    func test_getTypedArray_returns_array_of_optional_type() {
        let value = DataItem(value: ["1", "2", 0, "4", true, 2.5])
        let stringArray = value.getArray(of: String.self)
        let intArray = value.getArray(of: Int.self)
        let int64Array = value.getArray(of: Int64.self)
        let doubleArray = value.getArray(of: Double.self)
        let boolArray = value.getArray(of: Bool.self)
        XCTAssertEqual(stringArray, ["1", "2", nil, "4", nil, nil])
        XCTAssertEqual(intArray, [nil, nil, 0, nil, nil, 2])
        XCTAssertEqual(int64Array, [nil, nil, Int64(0), nil, nil, Int64(2)])
        XCTAssertEqual(doubleArray, [nil, nil, 0, nil, nil, 2.5])
        XCTAssertEqual(boolArray, [nil, nil, nil, nil, true, nil])
    }

    func test_getTypedArray_returns_nil_if_value_is_not_an_array() {
        let value = DataItem(value: "non array")
        let stringArray = value.getArray(of: String.self)
        let intArray = value.getArray(of: Int.self)
        let int64Array = value.getArray(of: Int64.self)
        let doubleArray = value.getArray(of: Double.self)
        let boolArray = value.getArray(of: Bool.self)
        XCTAssertNil(stringArray)
        XCTAssertNil(intArray)
        XCTAssertNil(int64Array)
        XCTAssertNil(doubleArray)
        XCTAssertNil(boolArray)
    }

    func test_getTypedDictionary_returns_dictionary_of_optional_type() {
        let value = DataItem(value: ["1": "1", "2": "2", "3": 0, "4": "4", "5": true, "6": 2.5])
        let stringDictionary = value.getDictionary(of: String.self)
        let intDictionary = value.getDictionary(of: Int.self)
        let int64Dictionary = value.getDictionary(of: Int64.self)
        let doubleDictionary = value.getDictionary(of: Double.self)
        let boolDictionary = value.getDictionary(of: Bool.self)
        XCTAssertEqual(stringDictionary, ["1": "1", "2": "2", "3": nil, "4": "4", "5": nil, "6": nil])
        XCTAssertEqual(intDictionary, ["1": nil, "2": nil, "3": 0, "4": nil, "5": nil, "6": 2])
        XCTAssertEqual(int64Dictionary, ["1": nil, "2": nil, "3": Int64(0), "4": nil, "5": nil, "6": Int64(2.5)])
        XCTAssertEqual(doubleDictionary, ["1": nil, "2": nil, "3": 0, "4": nil, "5": nil, "6": 2.5])
        XCTAssertEqual(boolDictionary, ["1": nil, "2": nil, "3": nil, "4": nil, "5": true, "6": nil])
    }

    func test_getTypedDictionary_returns_nil_if_value_is_not_a_dictionary() {
        let value = DataItem(value: "non dictionary")
        let stringDictionary = value.getDictionary(of: String.self)
        let intDictionary = value.getDictionary(of: Int.self)
        let int64Dictionary = value.getDictionary(of: Int64.self)
        let doubleDictionary = value.getDictionary(of: Double.self)
        let boolDictionary = value.getDictionary(of: Bool.self)
        XCTAssertNil(stringDictionary)
        XCTAssertNil(intDictionary)
        XCTAssertNil(int64Dictionary)
        XCTAssertNil(doubleDictionary)
        XCTAssertNil(boolDictionary)
    }
}
