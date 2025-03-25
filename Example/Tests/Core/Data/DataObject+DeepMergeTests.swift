//
//  DataObject+DeepMergeTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 17/03/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DataObjectDeepMergeTests: XCTestCase {

    func test_deepMerge_merges_indefinitely_by_default() {
        let initial: DataObject = [
            "1": [
                "2": [
                    "3": [
                        "4": [
                            "5.1": "value1"
                        ]
                    ]
                ]
            ]
        ]
        let other: DataObject = [
            "1": [
                "2": [
                    "3": [
                        "4": [
                            "5.2": "value2"
                        ]
                    ]
                ]
            ]
        ]
        let expected: DataObject = [
            "1": [
                "2": [
                    "3": [
                        "4": [
                            "5.1": "value1",
                            "5.2": "value2"
                        ]
                    ]
                ]
            ]
        ]

        let merged = initial.deepMerge(with: other)
        XCTAssertEqual(merged, expected)
    }

    func test_deepMerge_overrides_first_level_keys_if_depth_is_less_than_one() {
        let initial: DataObject = [
            "1": [
                "will_be_replaced": "value1"
            ]
        ]
        let other: DataObject = [
            "1": [
                "2": "value2"
            ]
        ]
        let expected: DataObject = [
            "1": [
                "2": "value2"
            ]
        ]
        let mergedWithZero = initial.deepMerge(with: other, depth: 0)
        let mergedWithNegative = initial.deepMerge(with: other, depth: -1)
        XCTAssertEqual(mergedWithZero, expected)
        XCTAssertEqual(mergedWithNegative, expected)
    }

    func test_deepMerge_merges_first_level_if_depth_is_one() {
        let initial: DataObject = [
            "1": [
                "2.1": "value1"
            ]
        ]
        let other: DataObject = [
            "1": [
                "2.2": "value2"
            ]
        ]
        let expected: DataObject = [
            "1": [
                "2.1": "value1",
                "2.2": "value2"
            ]
        ]
        let merged = initial.deepMerge(with: other, depth: 1)
        XCTAssertEqual(merged, expected)
    }

    func test_deepMerge_overrides_second_level_keys_if_depth_is_one() {
        let initial: DataObject = [
            "1": [
                "2": [
                    "will_be_replaced": "value1"
                ]
            ]
        ]
        let other: DataObject = [
            "1": [
                "2": [
                    "3": "value2"
                ]
            ]
        ]
        let expected: DataObject = [
            "1": [
                "2": [
                    "3": "value2"
                ]
            ]
        ]
        let merged = initial.deepMerge(with: other, depth: 1)
        XCTAssertEqual(merged, expected)
    }
    func test_deepMerge_merges_up_to_third_level_if_depth_is_three() {
        let initial: DataObject = [
            "1": [
                "2": [
                    "3.1": [
                        "4.1": "value1"
                    ],
                    "3.2": [
                        "4.1": "value1"
                    ]
                ]
            ]
        ]
        let other: DataObject = [
            "1": [
                "2": [
                    "3.1": [
                        "4.2": "value2"
                    ],
                    "3.3": [
                        "4.2": "value2"
                    ]
                ]
            ]
        ]
        let expected: DataObject = [
            "1": [
                "2": [
                    "3.1": [
                        "4.1": "value1",
                        "4.2": "value2"
                    ],
                    "3.2": [
                        "4.1": "value1"
                    ],
                    "3.3": [
                        "4.2": "value2"
                    ]
                ]
            ]
        ]
        let merged = initial.deepMerge(with: other, depth: 3)
        XCTAssertEqual(merged, expected)
    }

    func test_deepMerge_overrides_fourth_level_keys_if_depth_is_three() {
        let initial: DataObject = [
            "1": [
                "2": [
                    "3": [
                        "4": [
                            "will_be_replaced": "value1"
                        ]
                    ]
                ]
            ]
        ]
        let other: DataObject = [
            "1": [
                "2": [
                    "3": [
                        "4": [
                            "5": "value2"
                        ]
                    ]
                ]
            ]
        ]
        let expected: DataObject = [
            "1": [
                "2": [
                    "3": [
                        "4": [
                            "5": "value2"
                        ]
                    ]
                ]
            ]
        ]
        let merged = initial.deepMerge(with: other, depth: 3)
        XCTAssertEqual(merged, expected)
    }

    func test_deepMerge_merges_nulls() {
        let initial: DataObject = [
            "1": [
                "2": "value1"
            ]
        ]
        let other: DataObject = [
            "1": [
                "2": NSNull()
            ]
        ]
        let expected: DataObject = [
            "1": [
                "2": NSNull()
            ]
        ]
        let merged = initial.deepMerge(with: other)
        XCTAssertEqual(merged, expected)
    }
}
