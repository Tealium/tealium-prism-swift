//
//  LoadRule+ConverterTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 25/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LoadRuleConverterTests: XCTestCase {
    let converter = LoadRule.converter
    func test_convert_converts_loadRule_with_and() throws {
        let loadRule = try DataItem(jsonValue: [
            "id": "ruleId",
            "conditions": [
                "operator": "and",
                "children": [
                    [
                        "variable": ["path": "container.pageName"],
                        "operator": "equals",
                        "filter": ["value": "Home"]
                    ]
                ]
            ]
        ])
        let converted = converter.convert(dataItem: loadRule)
        let condition = Condition(variable: JSONPath["container"]["pageName"],
                                  operator: .equals(false),
                                  filter: "Home")
        XCTAssertEqual(converted, LoadRule(id: "ruleId",
                                           conditions: .and([.just(condition)])))
    }

    func test_convert_converts_loadRule_with_or() throws {
        let loadRule = try DataItem(jsonValue: [
            "id": "ruleId",
            "conditions": [
                "operator": "or",
                "children": [
                    [
                        "variable": ["path": "container.pageName"],
                        "operator": "equals",
                        "filter": ["value": "Home"]
                    ]
                ]
            ]
        ])
        let converted = converter.convert(dataItem: loadRule)
        let condition = Condition(variable: JSONPath["container"]["pageName"],
                                  operator: .equals(false),
                                  filter: "Home")
        XCTAssertEqual(converted, LoadRule(id: "ruleId",
                                           conditions: .or([.just(condition)])))
    }

    func test_convert_converts_loadRule_with_not() throws {
        let loadRule = try DataItem(jsonValue: [
            "id": "ruleId",
            "conditions": [
                "operator": "not",
                "children": [
                    [
                        "variable": ["path": "container.pageName"],
                        "operator": "equals",
                        "filter": ["value": "Home"]
                    ]
                ]
            ]
        ])
        let converted = converter.convert(dataItem: loadRule)
        let condition = Condition(variable: JSONPath["container"]["pageName"],
                                  operator: .equals(false),
                                  filter: "Home")
        XCTAssertEqual(converted, LoadRule(id: "ruleId",
                                           conditions: .not(.just(condition))))
    }

    func test_convert_converts_loadRule_with_just() throws {
        let loadRule = try DataItem(jsonValue: [
            "id": "ruleId",
            "conditions": [
                "variable": ["path": "container.pageName"],
                "operator": "equals",
                "filter": ["value": "Home"]
            ]
        ])
        let converted = converter.convert(dataItem: loadRule)
        let condition = Condition(variable: JSONPath["container"]["pageName"],
                                  operator: .equals(false),
                                  filter: "Home")
        XCTAssertEqual(converted, LoadRule(id: "ruleId",
                                           conditions: .just(condition)))

    }
}
