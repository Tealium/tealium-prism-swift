//
//  LowerCaseConfigurationTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 06/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LowerCaseConfigurationTests: XCTestCase {

    func test_init_with_empty_data_object_uses_default_all_variables() {
        guard let config = LowerCaseConfiguration(dataObject: [:]) else {
            XCTFail("Configuration should not be nil when allVariables defaults to true")
            return
        }
        XCTAssertEqual(config.allVariables, LowerCaseConfiguration.Defaults.allVariables)
        XCTAssertTrue(config.inputs.isEmpty)
    }

    func test_init_with_all_variables_true_parses_correctly() {
        let dataObject: DataObject = ["all_variables": true]
        guard let config = LowerCaseConfiguration(dataObject: dataObject) else {
            XCTFail("Configuration should not be nil when allVariables is true")
            return
        }
        XCTAssertEqual(config.allVariables, true)
    }

    func test_init_with_all_variables_false_parses_correctly() {
        let dataObject: DataObject = [
            "all_variables": false,
            "inputs": [ReferenceContainer.key("email").toDataObject()]
        ]
        guard let config = LowerCaseConfiguration(dataObject: dataObject) else {
            XCTFail("Configuration should not be nil when allVariables is false but inputs is non-empty")
            return
        }
        XCTAssertEqual(config.allVariables, false)
    }

    func test_init_with_all_variables_false_and_no_inputs_returns_nil() {
        let dataObject: DataObject = ["all_variables": false]
        XCTAssertNil(LowerCaseConfiguration(dataObject: dataObject))
    }

    func test_init_with_all_variables_false_and_empty_inputs_array_returns_nil() {
        let dataObject: DataObject = ["all_variables": false, "inputs": [DataObject]()]
        XCTAssertNil(LowerCaseConfiguration(dataObject: dataObject))
    }

    func test_init_with_missing_all_variables_uses_default() {
        guard let config = LowerCaseConfiguration(dataObject: ["inputs": [DataObject]()]) else {
            XCTFail("Configuration should not be nil when allVariables defaults to true")
            return
        }
        XCTAssertEqual(config.allVariables, LowerCaseConfiguration.Defaults.allVariables)
    }

    func test_init_with_inputs_parses_correctly() {
        let dataObject: DataObject = [
            "all_variables": false,
            "inputs": [ReferenceContainer.key("email").toDataObject()]
        ]
        guard let config = LowerCaseConfiguration(dataObject: dataObject) else {
            XCTFail("Configuration should not be nil when inputs is non-empty")
            return
        }
        XCTAssertEqual(config.inputs.count, 1)
        XCTAssertEqual(config.inputs.first, .key("email"))
    }

    func test_init_with_missing_inputs_returns_empty_array() {
        let dataObject: DataObject = ["all_variables": true]
        guard let config = LowerCaseConfiguration(dataObject: dataObject) else {
            XCTFail("Configuration should not be nil when allVariables is true")
            return
        }
        XCTAssertTrue(config.inputs.isEmpty)
    }

    func test_roundTrip_with_all_variables_true_preserves_data() {
        let original = LowerCaseConfiguration(allVariables: true)
        guard let restored = LowerCaseConfiguration(dataObject: original.toDataObject()) else {
            XCTFail("Restored configuration should not be nil")
            return
        }
        XCTAssertEqual(restored.allVariables, true)
    }

    func test_roundTrip_with_all_variables_false_and_no_inputs_returns_nil() {
        let original = LowerCaseConfiguration(allVariables: false)
        XCTAssertNil(LowerCaseConfiguration(dataObject: original.toDataObject()))
    }

    func test_roundTrip_with_inputs_preserves_data() {
        let original = LowerCaseConfiguration(allVariables: false, inputs: [.key("email")])
        guard let restored = LowerCaseConfiguration(dataObject: original.toDataObject()) else {
            XCTFail("Restored configuration should not be nil")
            return
        }
        XCTAssertEqual(restored.inputs.count, 1)
        XCTAssertEqual(restored.inputs.first, .key("email"))
    }
}
