//
//  Condition+LessThanOrEqualTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionLessThanOrEqualTests: XCTestCase {
    let payload: DataObject = [
        "string": "fourty five",
        "numberString": "45",
        "int": 45,
        "double": 3.14,
        "bool": true,
        "array": ["a", "b", "c"],
        "dictionary": ["key": 45],
        "null": NSNull(),
        "infinityString": "Infinity",
        "negativeInfinityString": "-Infinity",
        "nanString": "NaN",
        "infinity": Double.infinity,
        "negativeInfinity": -Double.infinity,
        "nan": Double.nan,
        "emptyString": ""
    ]

    func test_lessThanOrEqual_throws_for_string() {
        let condition = Condition.isLessThan(orEqual: true, variable: "string", number: "100")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                  case let .numberParsingError(parsing, source) = operationError.kind else {
                XCTFail("Should be number parsing error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
            XCTAssertEqual(parsing, "fourty five")
            XCTAssertEqual(source, "DataItem")
        }
    }

    func test_lessThanOrEqual_matches_number_strings() {
        let condition = Condition.isLessThan(orEqual: true, variable: "numberString", number: "100")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_when_stringified_numbers_are_equal() {
        let condition = Condition.isLessThan(orEqual: true, variable: "numberString", number: "45")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_throws_for_bool() {
        let condition = Condition.isLessThan(orEqual: true, variable: "bool", number: "10")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                  case let .numberParsingError(parsing, source) = operationError.kind else {
                XCTFail("Should be number parsing error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
            XCTAssertEqual(parsing, String(describing: true))
            XCTAssertEqual(source, "DataItem")
        }
    }

    func test_lessThanOrEqual_throws_for_array() {
        let condition = Condition.isLessThan(orEqual: true, variable: "array", number: "10")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                  case let .numberParsingError(parsing, source) = operationError.kind else {
                XCTFail("Should be number parsing error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
            XCTAssertEqual(parsing, String(describing: ["a", "b", "c"]))
            XCTAssertEqual(source, "DataItem")
        }
    }

    func test_lessThanOrEqual_throws_for_dictionary() {
        let condition = Condition.isLessThan(orEqual: true, variable: "dictionary", number: "10")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                  case let .numberParsingError(parsing, source) = operationError.kind else {
                XCTFail("Should be number parsing error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
            XCTAssertEqual(parsing, String(describing: ["key": 45]))
            XCTAssertEqual(source, "DataItem")
        }
    }

    func test_lessThanOrEqual_doesnt_match_if_int_greater_than_filter() {
        let condition = Condition.isLessThan(orEqual: true, variable: "int", number: "4")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_doesnt_match_if_double_greater_than_filter() {
        let condition = Condition.isLessThan(orEqual: true, variable: "double", number: "3.13")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_if_int_equals_filter() {
        let condition = Condition.isLessThan(orEqual: true, variable: "int", number: "45")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_if_double_equals_filter() {
        let condition = Condition.isLessThan(orEqual: true, variable: "double", number: "3.14")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_if_int_less_than_filter() {
        let condition = Condition.isLessThan(orEqual: true, variable: "int", number: "46")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_if_double_less_than_filter() {
        let condition = Condition.isLessThan(orEqual: true, variable: "double", number: "3.15")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_if_int_less_than_filter_in_nested_object() {
        let condition = Condition.isLessThan(orEqual: true,
                                             variable: VariableAccessor(path: ["dictionary"],
                                                                        variable: "key"),
                                             number: "46")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_throws_if_data_item_is_null() {
        let condition = Condition.isLessThan(orEqual: true, variable: "null", number: "1")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                  case let .numberParsingError(parsing, source) = operationError.kind else {
                XCTFail("Should be number parsing error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
            XCTAssertEqual(parsing, String(describing: NSNull()))
            XCTAssertEqual(source, "DataItem")
        }
    }

    func test_lessThanOrEqual_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.isLessThan(orEqual: true, variable: "missing", number: "1")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingDataItem = operationError.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_lessThanOrEqual_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.isLessThan(orEqual: true,
                                             variable: VariableAccessor(path: ["dictionary", "missing"],
                                                                        variable: "key"),
                                             number: "1")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingDataItem = operationError.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_lessThanOrEqual_doesnt_match_infinity() {
        let condition = Condition.isLessThan(orEqual: true, variable: "infinity", number: "10")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_infinity_equality() {
        let condition = Condition.isLessThan(orEqual: true, variable: "infinity", number: "Infinity")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_negative_infinity() {
        let condition = Condition.isLessThan(orEqual: true, variable: "negativeInfinity", number: "10")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_negative_infinity_equality() {
        let condition = Condition.isLessThan(orEqual: true, variable: "negativeInfinity", number: "-Infinity")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_doesnt_match_NaN() {
        let condition = Condition.isLessThan(orEqual: true, variable: "nan", number: "Infinity")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_doesnt_match_when_filter_is_NaN() {
        let condition = Condition.isLessThan(orEqual: true, variable: "negativeInfinity", number: "NaN")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_doesnt_match_two_NaNs() {
        let condition = Condition.isLessThan(orEqual: true, variable: "nan", number: "NaN")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_doesnt_match_infinity_string() {
        let condition = Condition.isLessThan(orEqual: true, variable: "infinityString", number: "10")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_matches_negative_infinity_string() {
        let condition = Condition.isLessThan(orEqual: true, variable: "negativeInfinityString", number: "10")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_doesnt_match_NaN_string() {
        let condition = Condition.isLessThan(orEqual: true, variable: "nanString", number: "Infinity")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_doesnt_match_two_NaNs_with_nanString() {
        let condition = Condition.isLessThan(orEqual: true, variable: "nanString", number: "NaN")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_lessThanOrEqual_throws_for_empty_string() {
        let condition = Condition.isLessThan(orEqual: true, variable: "emptyString", number: "99")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                  case let .numberParsingError(parsing, source) = operationError.kind else {
                XCTFail("Should be number parsing error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
            XCTAssertEqual(parsing, "")
            XCTAssertEqual(source, "DataItem")
        }
    }

    func test_lessThanOrEqual_throws_when_filter_is_empty_string() {
        let condition = Condition.isLessThan(orEqual: true, variable: "negativeInfinity", number: "")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                  case let .numberParsingError(parsing, source) = operationError.kind else {
                XCTFail("Should be number parsing error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
            XCTAssertEqual(parsing, "")
            XCTAssertEqual(source, "Filter")
        }
    }

    func test_lessThanOrEqual_throws_when_filter_cannot_be_parsed() {
        let condition = Condition.isLessThan(orEqual: true, variable: "negativeInfinity", number: "forty two")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                  case let .numberParsingError(parsing, source) = operationError.kind else {
                XCTFail("Should be number parsing error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
            XCTAssertEqual(parsing, "forty two")
            XCTAssertEqual(source, "Filter")
        }
    }

    func test_lessThanOrEqual_throws_when_filter_is_nil() {
        let condition = Condition(variable: "negativeInfinity", operator: .lessThan(true), filter: nil)
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingFilter = operationError.kind else {
                XCTFail("Should be missing filter error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }
}
