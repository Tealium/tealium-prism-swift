//
//  Rule+DataInputConvertibleTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class RuleDataInputConvertibleTests: XCTestCase {
    let converter = Condition.converter

    func test_convert_just_returns_item_directly() {
        let rule = Rule.just("string")
        let dataInput = rule.toDataInput()
        XCTAssertEqual(dataInput as? String, "string")
    }

    func test_convert_and_returns_object_with_operator_and_children() {
        let rule = Rule<String>.and(["string"])
        let dataInput = rule.toDataInput()
        XCTAssertEqual(dataInput as? [String: Any], [
            "operator": "and",
            "children": [
                "string"
            ]
        ])
    }

    func test_convert_or_returns_object_with_operator_and_children() {
        let rule = Rule<String>.or(["string"])
        let dataInput = rule.toDataInput()
        XCTAssertEqual(dataInput as? [String: Any], [
            "operator": "or",
            "children": [
                "string"
            ]
        ])
    }

    func test_convert_not_returns_object_with_operator_and_children() {
        let rule = Rule<String>.not("string")
        let dataInput = rule.toDataInput()
        XCTAssertEqual(dataInput as? [String: Any], [
            "operator": "not",
            "children": [
                "string"
            ]
        ])
    }

    func test_convert_nested_rules_returns_nested_objects() {
        let rule = Rule<String>.or([
            "string",
            .and([
                "string",
                .not("string")
            ])
        ])
        let dataInput = rule.toDataInput()
        XCTAssertEqual(dataInput as? [String: Any], [
            "operator": "or",
            "children": [
                "string",
                [
                    "operator": "and",
                    "children": [
                        "string",
                        [
                            "operator": "not",
                            "children": [
                                "string"
                            ]
                        ]
                    ]
                ]
            ]
        ])
    }
}
