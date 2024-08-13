//
//  SettingsManager+MergeTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 24/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class SettingsManagerMergeTests: XCTestCase {

    func test_merge_returns_a_merged_settings_with_all_modules_contained_in_all_settings() {
        let settingsList: [[String: [String: Any]]] = [
            [
                "module1": ["key": "value"],
                "module2": ["key": "value"]
            ],
            [
                "module2": ["key": "value"],
                "module3": ["key": "value"]
            ],
            [
                "module3": ["key": "value"],
                "module4": ["key": "value"]
            ],
        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList.map { SDKSettings(modulesSettings: $0) })
        XCTAssertEqual(mergedSettings.modulesSettings.keys.count, 4)
        settingsList.forEach { sdkSettings in
            sdkSettings.keys.forEach { moduleId in
                XCTAssertNotNil(mergedSettings.modulesSettings[moduleId])
            }
        }
    }

    func test_merge_merges_same_module_with_all_the_keys_contained_in_all_settings_for_that_module() {
        let settingsList: [[String: [String: Any]]] = [
            [
                "module": [
                    "key1": "value1",
                    "key2": "value1",
                    "key3": "value1"
                ]
            ],
            [
                "module": [
                    "key4": "value2",
                    "key5": "value2",
                    "key6": "value2"
                ]
            ],
            [
                "module": [
                    "key7": "value3",
                    "key8": "value3",
                    "key9": "value3"
                ]
            ],
        ]
        let expected = [
            "key1": "value1",
            "key2": "value1",
            "key3": "value1",
            "key4": "value2",
            "key5": "value2",
            "key6": "value2",
            "key7": "value3",
            "key8": "value3",
            "key9": "value3"
        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList.map { SDKSettings(modulesSettings: $0) })
        XCTAssertEqual(mergedSettings.modulesSettings["module"], expected)
    }

    func test_merge_with_same_module_replaces_previous_modules() {
        let settingsList: [[String: [String: Any]]] = [
            [
                "module": [
                    "key1": "value1",
                    "key2": "value1",
                    "key3": "value1"
                ]
            ],
            [
                "module": [
                    "key1": "value2",
                    "key2": "value2",
                    "key3": "value2"
                ]
            ],
            [
                "module": [
                    "key1": "value3",
                    "key2": "value3",
                    "key3": "value3"
                ]
            ],
        ]
        let expected = [
            "key1": "value3",
            "key2": "value3",
            "key3": "value3"
        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList.map { SDKSettings(modulesSettings: $0) })
        XCTAssertEqual(mergedSettings.modulesSettings["module"], expected)
    }

    func test_merge_only_merges_first_level_of_dictionary_and_replaces_others() {
        let settingsList: [[String: [String: Any]]] = [
            [
                "module": [
                    "complex_object": ["key1": "value1"],
                ]
            ],
            [
                "module": [
                    "key1": "value2",
                    "key2": "value2",
                    "key3": "value2",
                    "complex_object": ["key2": "value2"],
                ]
            ]
        ]
        let expected: [String: Any] = [
            "key1": "value2",
            "key2": "value2",
            "key3": "value2",
            "complex_object": ["key2": "value2"]
        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList.map { SDKSettings(modulesSettings: $0) })
        XCTAssertEqual(mergedSettings.modulesSettings["module"], expected)
    }

    func test_merge_with_just_one_settings_returns_that_first_settings() {
        let settingsList: [[String: [String: Any]]] = [
            [
                "module": [
                    "key1": "value1",
                    "key2": "value1",
                    "key3": "value1",
                ]
            ]
        ]
        let expected = [
            "key1": "value1",
            "key2": "value1",
            "key3": "value1"
        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList.map { SDKSettings(modulesSettings: $0) })
        XCTAssertEqual(mergedSettings.modulesSettings["module"], expected)
    }
}
