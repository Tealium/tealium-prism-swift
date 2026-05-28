//
//  LowercaseConfigurationTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 06/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LowercaseConfigurationTests: XCTestCase {

    func test_init_with_empty_data_object_returns_nil() {
        XCTAssertNil(LowercaseConfiguration(dataObject: [:]))
    }

    func test_init_with_allvariables_string_parses_to_allVariables_policy() {
        let dataObject: DataObject = ["variables": "allvariables"]
        guard let config = LowercaseConfiguration(dataObject: dataObject) else {
            XCTFail("Configuration should not be nil when policy is 'allvariables'")
            return
        }
        guard case .allVariables = config.policy else {
            XCTFail("Expected .allVariables policy")
            return
        }
    }

    func test_init_with_allvariables_string_case_insensitive() {
        let dataObject: DataObject = ["variables": "AllVariables"]
        guard let config = LowercaseConfiguration(dataObject: dataObject) else {
            XCTFail("Configuration should not be nil for case-insensitive allvariables")
            return
        }
        guard case .allVariables = config.policy else {
            XCTFail("Expected .allVariables policy")
            return
        }
    }

    func test_init_with_variables_array_parses_to_variables_policy() {
        let dataObject: DataObject = [
            "variables": [ReferenceContainer.key("email").toDataObject()]
        ]
        guard let config = LowercaseConfiguration(dataObject: dataObject) else {
            XCTFail("Configuration should not be nil when policy is a non-empty array")
            return
        }
        guard case .variables(let refs) = config.policy else {
            XCTFail("Expected .variables policy")
            return
        }
        XCTAssertEqual(refs.count, 1)
        XCTAssertEqual(refs.first, .key("email"))
    }

    func test_init_with_empty_variables_array_returns_variables_policy_with_empty_array() {
        let dataObject: DataObject = ["variables": [DataObject]()]
        guard let config = LowercaseConfiguration(dataObject: dataObject) else {
            XCTFail("Configuration should not be nil for an empty variables array")
            return
        }
        guard case .variables(let refs) = config.policy else {
            XCTFail("Expected .variables policy for empty array")
            return
        }
        XCTAssertTrue(refs.isEmpty)
    }

    func test_init_with_integer_at_variables_key_returns_nil() {
        let dataObject: DataObject = ["variables": 42]
        XCTAssertNil(LowercaseConfiguration(dataObject: dataObject))
    }

    func test_init_with_unknown_string_policy_returns_nil() {
        let dataObject: DataObject = ["variables": "unknown"]
        XCTAssertNil(LowercaseConfiguration(dataObject: dataObject))
    }

    func test_roundTrip_allVariables_policy_preserves_data() {
        let original = LowercaseConfiguration(policy: .allVariables)
        guard let restored = LowercaseConfiguration(dataObject: original.toDataObject()) else {
            XCTFail("Restored configuration should not be nil")
            return
        }
        guard case .allVariables = restored.policy else {
            XCTFail("Expected .allVariables policy after round trip")
            return
        }
    }

    func test_roundTrip_variables_policy_preserves_data() {
        let original = LowercaseConfiguration(policy: .variables([.key("email")]))
        guard let restored = LowercaseConfiguration(dataObject: original.toDataObject()) else {
            XCTFail("Restored configuration should not be nil")
            return
        }
        guard case .variables(let refs) = restored.policy else {
            XCTFail("Expected .variables policy after round trip")
            return
        }
        XCTAssertEqual(refs.count, 1)
        XCTAssertEqual(refs.first, .key("email"))
    }
}
