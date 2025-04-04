//
//  LoadRule+ConverterTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 25/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class LoadRuleConverterTests: XCTestCase {
    let converter = LoadRule.converter
    func test_convert_converts_loadRule_with_and() throws {
        let loadRule = try DataItem(serializing: [
            "id": "ruleId",
            "conditions": [
                "operator": "and",
                "children": [
                    [
                        "path": ["container"],
                        "variable": "pageName",
                        "operator": "equals",
                        "filter": "Home"
                    ]
                ]
            ]
        ])
        let converted = converter.convert(dataItem: loadRule)
        guard let conditions = converted?.conditions else {
            XCTFail("Conversion failed and returned nil")
            return
        }
        XCTAssertEqual(converted?.id, "ruleId")
        guard case let .and(children) = conditions else {
            XCTFail("Condition AND do not match converted value \(conditions)")
            return
        }
        XCTAssertEqual(children.count, 1)
        guard case let .just(item) = children.first else {
            XCTFail("Conditions condition children are not just an item \(children)")
            return
        }
        let expected = Condition(path: ["container"],
                                 variable: "pageName",
                                 operator: .equals(false),
                                 filter: "Home")
        XCTAssertEqual(item as? Condition, expected)
    }

    func test_convert_converts_loadRule_with_or() throws {
        let loadRule = try DataItem(serializing: [
            "id": "ruleId",
            "conditions": [
                "operator": "or",
                "children": [
                    [
                        "path": ["container"],
                        "variable": "pageName",
                        "operator": "equals",
                        "filter": "Home"
                    ]
                ]
            ]
        ])
        let converted = converter.convert(dataItem: loadRule)
        guard let conditions = converted?.conditions else {
            XCTFail("Conversion failed and returned nil")
            return
        }
        XCTAssertEqual(converted?.id, "ruleId")
        guard case let .or(children) = conditions else {
            XCTFail("Condition OR do not match converted value \(conditions)")
            return
        }
        XCTAssertEqual(children.count, 1)
        guard case let .just(item) = children.first else {
            XCTFail("Conditions condition children are not just an item \(children)")
            return
        }
        let expected = Condition(path: ["container"],
                                 variable: "pageName",
                                 operator: .equals(false),
                                 filter: "Home")
        XCTAssertEqual(item as? Condition, expected)
    }

    func test_convert_converts_loadRule_with_not() throws {
        let loadRule = try DataItem(serializing: [
            "id": "ruleId",
            "conditions": [
                "operator": "not",
                "children": [
                    [
                        "path": ["container"],
                        "variable": "pageName",
                        "operator": "equals",
                        "filter": "Home"
                    ]
                ]
            ]
        ])
        let converted = converter.convert(dataItem: loadRule)
        guard let conditions = converted?.conditions else {
            XCTFail("Conversion failed and returned nil")
            return
        }
        XCTAssertEqual(converted?.id, "ruleId")
        guard case let .not(child) = conditions else {
            XCTFail("Condition NOT do not match converted value \(conditions)")
            return
        }
        guard case let .just(item) = child else {
            XCTFail("Conditions condition children are not just an item \(child)")
            return
        }
        let expected = Condition(path: ["container"],
                                 variable: "pageName",
                                 operator: .equals(false),
                                 filter: "Home")
        XCTAssertEqual(item as? Condition, expected)
    }

    func test_convert_converts_loadRule_with_just() throws {
        let loadRule = try DataItem(serializing: [
            "id": "ruleId",
            "conditions": [
                "path": ["container"],
                "variable": "pageName",
                "operator": "equals",
                "filter": "Home"
            ]
        ])
        let converted = converter.convert(dataItem: loadRule)
        guard let conditions = converted?.conditions else {
            XCTFail("Conversion failed and returned nil")
            return
        }
        XCTAssertEqual(converted?.id, "ruleId")
        guard case let .just(item) = conditions else {
            XCTFail("Conditions condition children are not just an item \(conditions)")
            return
        }
        let expected = Condition(path: ["container"],
                                 variable: "pageName",
                                 operator: .equals(false),
                                 filter: "Home")
        XCTAssertEqual(item as? Condition, expected)
    }
}
