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
        let config = LowerCaseConfiguration(dataObject: [:])
        XCTAssertEqual(config.allVariables, LowerCaseConfiguration.Defaults.allVariables)
        XCTAssertTrue(config.inputs.isEmpty)
    }

    func test_init_with_all_variables_true_parses_correctly() {
        let dataObject: DataObject = ["all_variables": true]
        let config = LowerCaseConfiguration(dataObject: dataObject)
        XCTAssertEqual(config.allVariables, true)
    }

    func test_init_with_all_variables_false_parses_correctly() {
        let dataObject: DataObject = ["all_variables": false]
        let config = LowerCaseConfiguration(dataObject: dataObject)
        XCTAssertEqual(config.allVariables, false)
    }

    func test_init_with_missing_all_variables_uses_default() {
        let config = LowerCaseConfiguration(dataObject: ["inputs": [DataObject]()])
        XCTAssertEqual(config.allVariables, LowerCaseConfiguration.Defaults.allVariables)
    }

    func test_init_with_inputs_parses_correctly() {
        let dataObject: DataObject = [
            "all_variables": false,
            "inputs": [ReferenceContainer.key("email").toDataObject()]
        ]
        let config = LowerCaseConfiguration(dataObject: dataObject)
        XCTAssertEqual(config.inputs.count, 1)
        XCTAssertEqual(config.inputs.first, .key("email"))
    }

    func test_init_with_missing_inputs_returns_empty_array() {
        let dataObject: DataObject = ["all_variables": true]
        let config = LowerCaseConfiguration(dataObject: dataObject)
        XCTAssertTrue(config.inputs.isEmpty)
    }

    func test_roundTrip_with_all_variables_true_preserves_data() {
        let original = LowerCaseConfiguration(allVariables: true)
        let restored = LowerCaseConfiguration(dataObject: original.toDataObject())
        XCTAssertEqual(restored.allVariables, true)
    }

    func test_roundTrip_with_all_variables_false_preserves_data() {
        let original = LowerCaseConfiguration(allVariables: false)
        let restored = LowerCaseConfiguration(dataObject: original.toDataObject())
        XCTAssertEqual(restored.allVariables, false)
    }

    func test_roundTrip_with_inputs_preserves_data() {
        let original = LowerCaseConfiguration(allVariables: false, inputs: [.key("email")])
        let restored = LowerCaseConfiguration(dataObject: original.toDataObject())
        XCTAssertEqual(restored.inputs.count, 1)
        XCTAssertEqual(restored.inputs.first, .key("email"))
    }
}
