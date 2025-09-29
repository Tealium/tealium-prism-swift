//
//  DataItem+StringValueTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 13/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//
@testable import TealiumPrism
import XCTest

final class DataItemStringValueTests: XCTestCase {

    func test_double_can_be_read_as_any_number() {
        let output = DataItem(stringValue: "12.5")
        let roundOutput = DataItem(stringValue: "2.0")
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
        let output = DataItem(stringValue: "12")
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
        let output = DataItem(stringValue: "\"test\"")
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

    func test_getDataInput_from_stringValue_can_be_read_as_TealiumDataInput() {
        let int = DataItem(stringValue: "1")
        let double = DataItem(stringValue: "1.4")
        let intDouble = DataItem(stringValue: "2.0")
        let bool = DataItem(stringValue: "true")
        let string = DataItem(stringValue: "\"string\"")
        let array = DataItem(stringValue: "[\"1\",2,\"3.5\"]")
        let dictionary = DataItem(stringValue: "{\"1\":1,\"2\":2,\"3\":3.5}")
        let multiLevelDictionary = DataItem(stringValue: "{\"1\":[1,\"1\"],\"2\":[2,\"2\"],\"3\":[3.5,\"3.5\", true]}")
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
        XCTAssertEqual(tealiumDictionary?["3"] as? [DataInput], [3.5, "3.5", true])
    }

    func test_getDataInput_from_rounded_double_stringValue_can_only_be_cast_to_int() {
        // This is a limitation because the saved number is interpreted as an Int when read.
        // Use getDouble instead if you want to make sure to read the value as you want.
        let roundedDouble = DataItem(stringValue: "3.0")
        XCTAssertNil(roundedDouble.toDataInput() as? Double)
        XCTAssertNil(roundedDouble.toDataInput() as? Float)
        XCTAssertNotNil(roundedDouble.toDataInput() as? Int)
        XCTAssertNotNil(roundedDouble.get(as: Double.self))
    }

    func test_getTypedArray_returns_array_of_optional_type() {
        let value = DataItem(stringValue: "[\"1\", \"2\", 0, \"4\", true, 2.5]")
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
        let value = DataItem(stringValue: "\"non array\"")
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
        let value = DataItem(stringValue: "{\"1\": \"1\", \"2\": \"2\", \"3\": 0, \"4\": \"4\", \"5\": true, \"6\": 2.5}")
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
        let value = DataItem(stringValue: "\"non dictionary\"")
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

    func test_nan_and_infinity_strings_remain_strings() throws {
        let value = DataItem(stringValue: "[\"NaN\", \"Infinity\", \"-Infinity\"]")
        let result = value.getArray(of: String.self)
        XCTAssertEqual(result, ["NaN", "Infinity", "-Infinity"])
    }

    func test_iso_date_strings_remain_strings() throws {
        let encodedDate = try Tealium.jsonEncoder.encode(Date())
        // swiftlint:disable:next optional_data_string_conversion
        let stringDate = String(decoding: encodedDate, as: UTF8.self)
        let value = DataItem(stringValue: stringDate)
        let result = value.get(as: String.self)
        XCTAssertNotNil(result)
    }
}
