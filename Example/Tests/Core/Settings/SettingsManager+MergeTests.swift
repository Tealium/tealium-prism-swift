//
//  SettingsManager+MergeTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 24/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SettingsManagerMergeTests: XCTestCase {
    func orderedSettings(fromModulesList list: [[String: DataObject]]) -> [DataObject] {
        list.map { ["modules": $0] }
    }

    func test_merge_returns_a_settings_with_the_merged_cores() {
        let settingsList: [DataObject] = [
            ["core": ["key1": "value1"]],
            ["core": ["key2": "value2"]],
            ["core": ["key3": "value3"]]

        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList)
        let expected: DataObject = [
            "core": [
                "key1": "value1",
                "key2": "value2",
                "key3": "value3"
            ]
        ]
        XCTAssertEqual(mergedSettings, expected)
    }

    func test_merge_returns_a_merged_settings_with_all_modules_contained_in_all_settings() {
        let modulesSettingsList: [[String: DataObject]] = [
            [
                "module1": ["configuration": ["key": "value"]],
                "module2": ["configuration": ["key": "value"]]
            ],
            [
                "module2": ["configuration": ["key": "value"]],
                "module3": ["configuration": ["key": "value"]]
            ],
            [
                "module3": ["configuration": ["key": "value"]],
                "module4": ["configuration": ["key": "value"]]
            ]
        ]
        let settingsList = orderedSettings(fromModulesList: modulesSettingsList)
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList)
        XCTAssertEqual(mergedSettings.getDataDictionary(key: "modules")?.keys.count, 4)
        modulesSettingsList.forEach { sdkSettings in
            sdkSettings.keys.forEach { moduleId in
                XCTAssertNotNil(mergedSettings.getDataDictionary(key: "modules")?[moduleId])
            }
        }
    }

    func test_merge_merges_same_module_with_all_the_keys_contained_in_all_settings_for_that_module() {
        let settingsList = orderedSettings(fromModulesList: [
            [
                "module": [
                    "configuration": [
                        "key1": "value1",
                        "key2": "value1",
                        "key3": "value1"
                    ]
                ]
            ],
            [
                "module": [
                    "configuration": [
                        "key4": "value2",
                        "key5": "value2",
                        "key6": "value2"
                    ]
                ]
            ],
            [
                "module": [
                    "configuration": [
                        "key7": "value3",
                        "key8": "value3",
                        "key9": "value3"
                    ]
                ]
            ],
        ])
        let expected: DataObject = [
            "modules": [
                "module": [
                    "configuration": [
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
                ]
            ]
        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList)
        XCTAssertEqual(mergedSettings, expected)
    }

    func test_merge_with_same_module_replaces_previous_modules() {
        let settingsList = orderedSettings(fromModulesList: [
            [
                "module": [
                    "configuration": [
                        "key1": "value1",
                        "key2": "value1",
                        "key3": "value1"
                    ]
                ]
            ],
            [
                "module": [
                    "configuration": [
                        "key1": "value2",
                        "key2": "value2",
                        "key3": "value2"
                    ]
                ]
            ],
            [
                "module": [
                    "configuration": [
                        "key1": "value3",
                        "key2": "value3",
                        "key3": "value3"
                    ]
                ]
            ],
        ])
        let expected: DataObject = [
            "modules": [
                "module": [
                    "configuration": [
                        "key1": "value3",
                        "key2": "value3",
                        "key3": "value3"
                    ]
                ]
            ]
        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList)
        XCTAssertEqual(mergedSettings, expected)
    }

    func test_merge_only_merges_first_level_of_dictionary_and_replaces_others() throws {
        let settingsList = orderedSettings(fromModulesList: [
            [
                "module": [
                    "configuration": [
                        "complex_object": ["key1": "value1"],
                    ]
                ]
            ],
            [
                "module": [
                    "configuration": try DataItem(serializing: [
                        "key1": "value2",
                        "key2": "value2",
                        "key3": "value2",
                        "complex_object": ["key2": "value2"],
                    ])
                ]
            ]
        ])
        let expected: DataObject = [
            "modules": [
                "module": [
                    "configuration": try DataItem(serializing: [
                        "key1": "value2",
                        "key2": "value2",
                        "key3": "value2",
                        "complex_object": ["key2": "value2"]
                    ])
                ]
            ]
        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList)
        XCTAssertEqual(mergedSettings, expected)
    }

    func test_merge_with_just_one_settings_returns_that_first_settings() {
        let settingsList = orderedSettings(fromModulesList: [
            [
                "module": [
                    "configuration": [
                        "key1": "value1",
                        "key2": "value1",
                        "key3": "value1",
                    ]
                ]
            ]
        ])
        let expected: DataObject = [
            "modules": [
                "module": [
                    "configuration": [
                        "key1": "value1",
                        "key2": "value1",
                        "key3": "value1"
                    ]
                ]
            ]
        ]
        let mergedSettings = SettingsManager.merge(orderedSettings: settingsList)
        XCTAssertEqual(mergedSettings, expected)
    }
}
