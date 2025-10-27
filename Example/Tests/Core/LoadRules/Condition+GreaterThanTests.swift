//
//  Condition+GreaterThanTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConditionGreaterThanTests: XCTestCase {
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

    func test_greaterThan_throws_for_string() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "string", number: "10")
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

    func test_greaterThan_matches_number_string() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "numberString", number: "10")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_greaterThan_throws_for_bool() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "bool", number: "10")
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

    func test_greaterThan_throws_for_array() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "array", number: "10")
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

    func test_greaterThan_throws_for_dictionary() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "dictionary", number: "10")
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

    func test_greaterThan_matches_if_int_greater_than_filter() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "int", number: "4")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_greaterThan_matches_if_double_greater_than_filter() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "double", number: "3.13")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_greaterThan_doesnt_match_if_int_equals_filter() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "int", number: "45")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_greaterThan_doesnt_match_if_double_equals_filter() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "double", number: "3.14")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_greaterThan_doesnt_match_if_int_less_than_filter() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "int", number: "46")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_greaterThan_doesnt_match_if_double_less_than_filter() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "double", number: "3.15")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_greaterThan_matches_if_int_greater_than_filter_in_nested_object() {
        let condition = Condition.isGreaterThan(orEqual: false,
                                                variable: VariableAccessor(path: ["dictionary"],
                                                                           variable: "key"),
                                                number: "44")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_greaterThan_throws_if_data_item_is_null() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "null", number: "1")
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

    func test_greaterThan_throws_for_keys_missing_from_the_payload() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "missing", number: "1")
        XCTAssertThrowsError(try condition.matches(payload: payload)) { error in
            guard let operationError = error as? ConditionEvaluationError,
                    case .missingDataItem = operationError.kind else {
                XCTFail("Should be missing data item error, found: \(error)")
                return
            }
            XCTAssertEqual(operationError.condition, condition)
        }
    }

    func test_greaterThan_throws_for_keys_with_wrong_path_from_the_payload() {
        let condition = Condition.isGreaterThan(orEqual: false,
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

    func test_greaterThan_matches_infinity() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "infinity", number: "10")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_greaterThan_doesnt_match_negative_infinity() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "negativeInfinity", number: "10")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_greaterThan_doesnt_match_NaN() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "nan", number: "-Infinity")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_greaterThan_matches_infinity_string() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "infinityString", number: "10")
        XCTAssertTrue(try condition.matches(payload: payload))
    }

    func test_greaterThan_doesnt_match_negative_infinity_string() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "negativeInfinityString", number: "10")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_greaterThan_doesnt_match_NaN_string() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "nanString", number: "-Infinity")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_greaterThan_doesnt_match_when_filter_is_NaN() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "infinity", number: "NaN")
        XCTAssertFalse(try condition.matches(payload: payload))
    }

    func test_greaterThan_throws_for_empty_string() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "emptyString", number: "-99")
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

    func test_greaterThan_throws_when_filter_is_empty_string() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "infinity", number: "")
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

    func test_greaterThan_throws_when_filter_cannot_be_parsed() {
        let condition = Condition.isGreaterThan(orEqual: false, variable: "infinity", number: "forty two")
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

    func test_greaterThan_throws_when_filter_is_nil() {
        let condition = Condition(variable: "infinity", operator: .greaterThan(false), filter: nil)
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
