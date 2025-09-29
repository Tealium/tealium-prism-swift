//
//  Rule+ConverterTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

extension Rule where Item: Equatable {

    func equals<Other>(_ other: Rule<Other>) -> Bool {
        switch (self, other) {
        case let (.and(lhs), .and(rhs)):
            for (left, right) in zip(lhs, rhs) where !left.equals(right) {
                return false
            }
            return true
        case let (.or(lhs), .or(rhs)):
            for (left, right) in zip(lhs, rhs) where !left.equals(right) {
                return false
            }
            return true
        case let (.not(lhs), .not(rhs)):
            return lhs.equals(rhs)
        case let (.just(lhs), .just(rhs)):
            return lhs == rhs as? Item
        default:
            return false
        }
    }
}

final class RuleConverterTests: XCTestCase {
    let converter = Rule.converter(ruleItemConverter: Condition.converter)

    func test_init_from_and_of_conditions() throws {
        let item = try DataItem(serializing: [
            "operator": "and",
            "children": [
                [
                    "variable": "pageName1",
                    "path": ["container1"],
                    "operator": "equals",
                    "filter": "Home1"
                ],
                [
                    "variable": "pageName2",
                    "path": ["container2"],
                    "operator": "equals",
                    "filter": "Home2"
                ]
            ]
        ])
        let expected = Rule<Condition>.and([
            .just(Condition(path: ["container1"],
                            variable: "pageName1",
                            operator: .equals(false),
                            filter: "Home1")),
            .just(Condition(path: ["container2"],
                            variable: "pageName2",
                            operator: .equals(false),
                            filter: "Home2")),
        ])
        guard let converted = item.getConvertible(converter: converter) else {
            XCTFail("Failed to convert Rule")
            return
        }
        XCTAssertTrue(expected.equals(converted), "Expected \(expected) is not equal to \(converted)")
    }

    func test_init_from_or_of_conditions() throws {
        let item = try DataItem(serializing: [
            "operator": "or",
            "children": [
                [
                    "variable": "pageName1",
                    "path": ["container1"],
                    "operator": "equals",
                    "filter": "Home1"
                ],
                [
                    "variable": "pageName2",
                    "path": ["container2"],
                    "operator": "equals",
                    "filter": "Home2"
                ]
            ]
        ])
        let expected = Rule<Condition>.or([
            .just(Condition(path: ["container1"],
                            variable: "pageName1",
                            operator: .equals(false),
                            filter: "Home1")),
            .just(Condition(path: ["container2"],
                            variable: "pageName2",
                            operator: .equals(false),
                            filter: "Home2")),
        ])

        guard let converted = item.getConvertible(converter: converter) else {
            XCTFail("Failed to convert Rule")
            return
        }
        XCTAssertTrue(expected.equals(converted), "Expected \(expected) is not equal to \(converted)")
    }

    func test_init_from_not_of_one_condition() throws {
        let item = try DataItem(serializing: [
            "operator": "not",
            "children": [
                [
                    "variable": "pageName1",
                    "path": ["container1"],
                    "operator": "equals",
                    "filter": "Home1"
                ]
            ]
        ])
        let expected = Rule<Condition>.not(
            .just(Condition(path: ["container1"],
                            variable: "pageName1",
                            operator: .equals(false),
                            filter: "Home1"))
        )

        guard let converted = item.getConvertible(converter: converter) else {
            XCTFail("Failed to convert Rule")
            return
        }
        XCTAssertTrue(expected.equals(converted), "Expected \(expected) is not equal to \(converted)")
    }

    func test_init_from_nested_children() throws {
        let item = DataItem(stringValue: try jsonStringFromBundle("NestedMixedConditionRule"))

        func condition(_ variable: String) -> Condition {
            Condition(path: ["container"],
                      variable: variable,
                      operator: .equals(false),
                      filter: "Home")
        }
        let expected = Rule<Condition>.and([
            .or([
                .just(condition("pageName_AND_OR")),
                .not(.and([
                    .just(condition("pageName_AND_OR_NOT_AND")),
                    .not(.just(condition("pageName_AND_OR_NOT_AND_NOT"))),
                ]))
            ]),
            .just(Condition(path: ["container"],
                            variable: "pageName_AND",
                            operator: .equals(false),
                            filter: "Home")),
        ])

        guard let converted = item.getConvertible(converter: converter) else {
            XCTFail("Failed to convert Rule")
            return
        }
        XCTAssertTrue(expected.equals(converted), "Expected \(expected) is not equal to \(converted)")
    }
}
