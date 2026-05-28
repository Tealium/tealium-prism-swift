//
//  LenientConvertersTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 11/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class LenientConvertersTests: XCTestCase {

    // MARK: - DoubleConverter Tests

    func test_doubleConverter_converts_double_directly() {
        let dataItem = DataItem(value: 42.5)
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, 42.5)
    }

    func test_doubleConverter_converts_int_to_double() {
        let dataItem = DataItem(value: 42)
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, 42.0)
    }

    func test_doubleConverter_converts_string_to_double() {
        let dataItem = DataItem(value: "42.5")
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, 42.5)
    }

    func test_doubleConverter_converts_string_integer_to_double() {
        let dataItem = DataItem(value: "42")
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, 42.0)
    }

    func test_doubleConverter_returns_nil_for_invalid_string() {
        let dataItem = DataItem(value: "not a number")
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_doubleConverter_returns_nil_for_bool() {
        let dataItem = DataItem(value: true)
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_doubleConverter_converts_negative_double() {
        let dataItem = DataItem(value: "-123.456")
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, -123.456)
    }

    func test_doubleConverter_converts_scientific_notation() {
        let dataItem = DataItem(value: "1.23e2")
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, 123.0)
    }

    func test_doubleConverter_handles_infinity() {
        let dataItem = DataItem(value: Double.infinity)
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, Double.infinity)
    }

    func test_doubleConverter_handles_negative_infinity() {
        let dataItem = DataItem(value: -Double.infinity)
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, -Double.infinity)
    }

    func test_doubleConverter_handles_infinity_string() {
        let dataItem = DataItem(value: "Infinity")
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, Double.infinity)
    }

    func test_doubleConverter_handles_negative_infinity_string() {
        let dataItem = DataItem(value: "-Infinity")
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertEqual(result, -Double.infinity)
    }

    func test_doubleConverter_handles_nan() {
        let dataItem = DataItem(value: Double.nan)
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertTrueOptional(result?.isNaN)
    }

    func test_doubleConverter_handles_nan_string() {
        let dataItem = DataItem(value: "NaN")
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertTrueOptional(result?.isNaN)
    }

    func test_doubleConverter_returns_nil_for_array() {
        let dataItem = DataItem(value: [1, 2, 3])
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_doubleConverter_returns_nil_for_object() {
        let dataItem = DataItem(value: ["key": "value"])
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_doubleConverter_returns_nil_for_nsNull() {
        let dataItem = DataItem(value: NSNull())
        let result = LenientConverters.double.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    // MARK: - IntConverter Tests

    func test_intConverter_converts_int_directly() {
        let dataItem = DataItem(value: 42)
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, 42)
    }

    func test_intConverter_converts_string_to_int() {
        let dataItem = DataItem(value: "42")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, 42)
    }

    func test_intConverter_converts_double_string_to_int() {
        let dataItem = DataItem(value: "42.5")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, 42)
    }

    func test_intConverter_converts_double_to_int_truncating() {
        let dataItem = DataItem(value: 42.9)
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, 42)
    }

    func test_intConverter_returns_nil_for_invalid_string() {
        let dataItem = DataItem(value: "not a number")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_intConverter_returns_nil_for_bool() {
        let dataItem = DataItem(value: true)
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_intConverter_converts_negative_int() {
        let dataItem = DataItem(value: "-123")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, -123)
    }

    func test_intConverter_converts_zero() {
        let dataItem = DataItem(value: "0")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, 0)
    }

    func test_intConverter_returns_nil_for_array() {
        let dataItem = DataItem(value: [1, 2, 3])
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_intConverter_returns_nil_for_object() {
        let dataItem = DataItem(value: ["key": "value"])
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_intConverter_returns_nil_for_nsNull() {
        let dataItem = DataItem(value: NSNull())
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    // MARK: - IntConverter Edge Case Tests

    func test_intConverter_returns_int_max_for_double_infinity() {
        let dataItem = DataItem(value: Double.infinity)
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, Int.max)
    }

    func test_intConverter_returns_int_min_for_double_negative_infinity() {
        let dataItem = DataItem(value: -Double.infinity)
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, Int.min)
    }

    func test_intConverter_returns_nil_for_double_nan() {
        let dataItem = DataItem(value: Double.nan)
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_intConverter_returns_nil_for_nan_string() {
        let dataItem = DataItem(value: "NaN")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_intConverter_converts_Infinity_string_to_Int_max() {
        let dataItem = DataItem(value: "Infinity")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, Int.max)
    }

    func test_intConverter_converts_negative_Infinity_string_to_Int_max() {
        let dataItem = DataItem(value: "-Infinity")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, Int.min)
    }

    func test_intConverter_converts_out_of_bounds_number_to_Int_max() {
        let dataItem = DataItem(value: "100000000000000000000000000000")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, Int.max)
    }

    func test_intConverter_converts_negative_out_of_bounds_number_to_Int_min() {
        let dataItem = DataItem(value: "-100000000000000000000000000000")
        let result = LenientConverters.int.convert(dataItem: dataItem)
        XCTAssertEqual(result, Int.min)
    }

    // MARK: - BoolConverter Tests

    func test_boolConverter_converts_bool_directly() {
        let trueItem = DataItem(value: true)
        let falseItem = DataItem(value: false)
        XCTAssertTrueOptional(LenientConverters.bool.convert(dataItem: trueItem))
        XCTAssertFalseOptional(LenientConverters.bool.convert(dataItem: falseItem))
    }

    func test_boolConverter_converts_string_true_variations() {
        let trueStrings = ["true", "True", "TRUE", "  true  ", "yes", "YES", "Yes", "1"]
        for trueString in trueStrings {
            let dataItem = DataItem(value: trueString)
            let result = LenientConverters.bool.convert(dataItem: dataItem)
            XCTAssertTrueOptional(result)
        }
    }

    func test_boolConverter_converts_string_false_variations() {
        let falseStrings = ["false", "False", "FALSE", "  false  ", "no", "NO", "No", "0"]
        for falseString in falseStrings {
            let dataItem = DataItem(value: falseString)
            let result = LenientConverters.bool.convert(dataItem: dataItem)
            XCTAssertEqual(result, false, "Failed to convert '\(falseString)' to false")
        }
    }

    func test_boolConverter_converts_int_zero_to_false() {
        let dataItem = DataItem(value: 0)
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertEqual(result, false)
    }

    func test_boolConverter_converts_int_one_to_true() {
        let dataItem = DataItem(value: 1)
        XCTAssertTrueOptional(LenientConverters.bool.convert(dataItem: dataItem))
    }

    func test_boolConverter_returns_nil_for_nonzero_integers() {
        let negativeItem = DataItem(value: -1)
        let largeItem = DataItem(value: 100)
        XCTAssertNil(LenientConverters.bool.convert(dataItem: negativeItem))
        XCTAssertNil(LenientConverters.bool.convert(dataItem: largeItem))
    }

    func test_boolConverter_returns_nil_for_invalid_string() {
        let dataItem = DataItem(value: "maybe")
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_boolConverter_returns_nil_for_double() {
        let dataItem = DataItem(value: 1.5)
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    // MARK: - BoolConverter Edge Case Tests

    func test_boolConverter_returns_nil_for_double_infinity() {
        let dataItem = DataItem(value: Double.infinity)
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_boolConverter_returns_nil_for_double_negative_infinity() {
        let dataItem = DataItem(value: -Double.infinity)
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_boolConverter_returns_nil_for_double_nan() {
        let dataItem = DataItem(value: Double.nan)
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_boolConverter_handles_large_positive_integer() {
        let dataItem = DataItem(value: Int.max)
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_boolConverter_handles_large_negative_integer() {
        let dataItem = DataItem(value: Int.min)
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_boolConverter_returns_nil_for_array() {
        let dataItem = DataItem(value: [1, 2, 3])
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_boolConverter_returns_nil_for_object() {
        let dataItem = DataItem(value: ["key": "value"])
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_boolConverter_returns_nil_for_nsNull() {
        let dataItem = DataItem(value: NSNull())
        let result = LenientConverters.bool.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    // MARK: - StringConverter Tests

    func test_stringConverter_converts_string_directly() {
        let dataItem = DataItem(value: "hello")
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "hello")
    }

    func test_stringConverter_converts_int_to_string() {
        let dataItem = DataItem(value: 42)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "42")
    }

    func test_stringConverter_converts_double_to_string() {
        let dataItem = DataItem(value: 42.5)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "42.5")
    }

    func test_stringConverter_converts_bool_true_to_string() {
        let dataItem = DataItem(value: true)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "true")
    }

    func test_stringConverter_converts_bool_false_to_string() {
        let dataItem = DataItem(value: false)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "false")
    }

    func test_stringConverter_converts_negative_int() {
        let dataItem = DataItem(value: -123)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "-123")
    }

    func test_stringConverter_converts_zero() {
        let dataItem = DataItem(value: 0)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "0")
    }

    func test_stringConverter_converts_empty_string() {
        let dataItem = DataItem(value: "")
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "")
    }

    // MARK: - StringConverter Edge Case Tests

    func test_stringConverter_converts_infinity_to_string() {
        let dataItem = DataItem(value: Double.infinity)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "Infinity")
    }

    func test_stringConverter_converts_negative_infinity_to_string() {
        let dataItem = DataItem(value: -Double.infinity)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "-Infinity")
    }

    func test_stringConverter_converts_nan_to_string() {
        let dataItem = DataItem(value: Double.nan)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "NaN")
    }

    func test_stringConverter_formats_whole_numbers_without_decimal() {
        let dataItem = DataItem(value: 1.0)
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertEqual(result, "1")
    }

    func test_stringConverter_returns_nil_for_array() {
        let dataItem = DataItem(value: [1, 2, 3])
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_stringConverter_returns_nil_for_object() {
        let dataItem = DataItem(value: ["key": "value"])
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    func test_stringConverter_returns_nil_for_nsNull() {
        let dataItem = DataItem(value: NSNull())
        let result = LenientConverters.string.convert(dataItem: dataItem)
        XCTAssertNil(result)
    }

    // MARK: - Integration Tests with DataItemExtractor

    func test_converters_work_with_dataObject_getConvertible() {
        let dataObject = DataObject(dictionary: [
            "doubleAsString": "123.45",
            "intAsString": "42",
            "boolAsString": "true",
            "intAsDouble": 42.9,
            "boolAsInt": 1,
            "intAsStringForString": "123"
        ])

        let doubleValue = dataObject.getConvertible(key: "doubleAsString", converter: LenientConverters.double)
        XCTAssertEqual(doubleValue, 123.45)

        let intValue = dataObject.getConvertible(key: "intAsString", converter: LenientConverters.int)
        XCTAssertEqual(intValue, 42)

        let boolValue = dataObject.getConvertible(key: "boolAsString", converter: LenientConverters.bool)
        XCTAssertTrueOptional(boolValue)

        let intFromDouble = dataObject.getConvertible(key: "intAsDouble", converter: LenientConverters.int)
        XCTAssertEqual(intFromDouble, 42)

        let boolFromInt = dataObject.getConvertible(key: "boolAsInt", converter: LenientConverters.bool)
        XCTAssertTrueOptional(boolFromInt)

        let stringValue = dataObject.getConvertible(key: "intAsStringForString", converter: LenientConverters.string)
        XCTAssertEqual(stringValue, "123")
    }

    func test_converters_return_nil_for_missing_keys() {
        let dataObject = DataObject(dictionary: [:])

        let doubleValue = dataObject.getConvertible(key: "missing", converter: LenientConverters.double)
        XCTAssertNil(doubleValue)

        let intValue = dataObject.getConvertible(key: "missing", converter: LenientConverters.int)
        XCTAssertNil(intValue)

        let boolValue = dataObject.getConvertible(key: "missing", converter: LenientConverters.bool)
        XCTAssertNil(boolValue)

        let stringValue = dataObject.getConvertible(key: "missing", converter: LenientConverters.string)
        XCTAssertNil(stringValue)
    }

    func test_converters_handle_edge_cases_from_dataObject() {
        let dataObject = DataObject(dictionary: [
            "largeDouble": Double(Int.max) + 1000,
            "infinity": Double.infinity,
            "nan": Double.nan,
            "negativeInfinity": -Double.infinity,
            "infinityString": "Infinity",
            "nanString": "NaN",
            "negativeInfinityString": "-Infinity"
        ])

        // These should all return clamped values, and nil for NaNs
        XCTAssertEqual(dataObject.getConvertible(key: "largeDouble", converter: LenientConverters.int), Int.max)
        XCTAssertEqual(dataObject.getConvertible(key: "infinity", converter: LenientConverters.int), Int.max)
        XCTAssertEqual(dataObject.getConvertible(key: "infinityString", converter: LenientConverters.int), Int.max)
        XCTAssertNil(dataObject.getConvertible(key: "nan", converter: LenientConverters.int))
        XCTAssertNil(dataObject.getConvertible(key: "nanString", converter: LenientConverters.int))
        XCTAssertEqual(dataObject.getConvertible(key: "negativeInfinity", converter: LenientConverters.int), Int.min)
        XCTAssertEqual(dataObject.getConvertible(key: "negativeInfinityString", converter: LenientConverters.int), Int.min)

        // Bool conversions should also return nil
        XCTAssertNil(dataObject.getConvertible(key: "infinity", converter: LenientConverters.bool))
        XCTAssertNil(dataObject.getConvertible(key: "nan", converter: LenientConverters.bool))

        // String conversion should handle these gracefully
        XCTAssertEqual(dataObject.getConvertible(key: "infinity", converter: LenientConverters.string), "Infinity")
        XCTAssertEqual(dataObject.getConvertible(key: "nan", converter: LenientConverters.string), "NaN")
        XCTAssertEqual(dataObject.getConvertible(key: "negativeInfinity", converter: LenientConverters.string), "-Infinity")
    }
}
