//
//  PersistDataValueConfigurationTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 18/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class PersistDataValueConfigurationTests: XCTestCase {

    func test_init_with_empty_data_object_returns_nil() {
        let config = PersistDataValueConfiguration(dataObject: [:])
        XCTAssertNil(config)
    }

    func test_init_with_all_params_is_successful() {
        let config: DataObject = [
            "parameters": [
                "update_policy": "allow_update",
                "duration": Int64(-2),
                "input": ["key": "test_source"]
            ] as DataObject,
            "destination": [
                "key": "test_dest"
            ]
        ]
        guard let result = PersistDataValueConfiguration(dataObject: config) else {
            XCTFail("Configuration should be created")
            return
        }
        XCTAssertEqual(result.updatePolicy, .allowUpdate)
        XCTAssertEqual(result.expiryPolicy, .session)
        XCTAssertEqual(result.destination, .key("test_dest"))
        XCTAssertEqual(result.input.toDataInput() as? [String: String], ["key": "test_source"])
    }

    func test_init_with_missing_update_policy_uses_default() {
        let config: DataObject = [
            "parameters": [
                // "update_policy" is missing
                "duration": Int64(-2),
                "input": ["key": "test_source"]
            ] as DataObject,
            "destination": [
                "key": "test_dest"
            ]
        ]
        guard let result = PersistDataValueConfiguration(dataObject: config) else {
            XCTFail("Configuration should be created with default update policy")
            return
        }
        XCTAssertEqual(result.updatePolicy, .allowUpdate)
    }

    func test_init_with_missing_duration_uses_default() {
        let config: DataObject = [
            "parameters": [
                "update_policy": "allow_update",
                // "duration" is missing
                "input": ["key": "test_source"]
            ] as DataObject,
            "destination": [
                "key": "test_dest"
            ]
        ]
        guard let result = PersistDataValueConfiguration(dataObject: config) else {
            XCTFail("Configuration should be created with default expiry policy")
            return
        }
        XCTAssertEqual(result.expiryPolicy, .session)
    }

    func test_init_with_missing_input_returns_nil() {
        let config: DataObject = [
            "parameters": [
                "update_policy": "allow_update",
                "duration": Int64(-2),
                // "input" is missing
            ] as DataObject,
            "destination": [
                "key": "test_dest"
            ]
        ]
        XCTAssertNil(PersistDataValueConfiguration(dataObject: config))
    }

    func test_roundTrip_with_session_forever_untilRestart_preserves_data() {
        let originalPolicies: [ExpiryPolicy] = [.session, .forever, .untilRestart]
        for originalPolicy in originalPolicies {
            let original = makeConfiguration(expiryPolicy: originalPolicy)
            let restored = PersistDataValueConfiguration(dataObject: original.toDataObject())
            XCTAssertEqual(restored?.expiryPolicy, originalPolicy)
        }
    }

    func test_roundTrip_with_duration_preserves_data() {
        let original = makeConfiguration(expiryPolicy: .duration(5.minutes))
        let dataObject = original.toDataObject()
        guard let parameters = dataObject.getDataDictionary(key: OperationKeys.parameters) else {
            XCTFail("Expected parameters in data object")
            return
        }
        XCTAssertNotNil(parameters.get(key: PersistDataValueConfiguration.Keys.duration, as: Int64.self))
        let restored = PersistDataValueConfiguration(dataObject: dataObject)
        XCTAssertEqual(restored?.expiryPolicy, .duration(TimeFrame(unit: .seconds, interval: 300)))
    }

    func test_toDataObject_uses_duration_key() {
        let config = makeConfiguration(expiryPolicy: .session)
        let dataObject = config.toDataObject()
        guard let parameters = dataObject.getDataDictionary(key: OperationKeys.parameters) else {
            XCTFail("Expected parameters in data object")
            return
        }
        XCTAssertNotNil(parameters.get(key: PersistDataValueConfiguration.Keys.duration, as: Int64.self))
    }

    func test_roundTrip_with_reference_input_preserves_data() {
        let config = PersistDataValueConfiguration(
            destination: .key("dest"),
            input: .reference(.key("source")),
            expiryPolicy: .session,
            updatePolicy: .allowUpdate
        )
        let restored = PersistDataValueConfiguration(dataObject: config.toDataObject())
        guard case .reference(let ref) = restored?.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("source"))
    }

    func test_roundTrip_with_constant_input_preserves_data() {
        let config = PersistDataValueConfiguration(
            destination: .key("dest"),
            input: .constant(ValueContainer("constant_value")),
            expiryPolicy: .session,
            updatePolicy: .allowUpdate
        )
        let restored = PersistDataValueConfiguration(dataObject: config.toDataObject())
        guard case .constant(let value) = restored?.input else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(value.value.get(), "constant_value")
    }

    func test_roundTrip_with_keepFirstValue_preserves_updatePolicy() {
        let config = makeConfiguration(expiryPolicy: .session, updatePolicy: .keepFirstValue)
        let restored = PersistDataValueConfiguration(dataObject: config.toDataObject())
        XCTAssertEqual(restored?.updatePolicy, .keepFirstValue)
    }

    func test_init_with_invalid_duration_uses_default() {
        let config: DataObject = [
            "parameters": [
                "update_policy": "allow_update",
                "duration": Int64(-99),
                "input": ["key": "test_source"]
            ] as DataObject,
            "destination": [
                "key": "test_dest"
            ]
        ]
        guard let result = PersistDataValueConfiguration(dataObject: config) else {
            XCTFail("Configuration should be created with default expiry policy when duration is invalid")
            return
        }
        XCTAssertEqual(result.expiryPolicy, .session)
    }

    func test_init_with_invalid_update_policy_uses_default() {
        let config: DataObject = [
            "parameters": [
                "update_policy": "invalid_policy",
                "duration": Int64(-2),
                "input": ["key": "test_source"]
            ] as DataObject,
            "destination": [
                "key": "test_dest"
            ]
        ]
        guard let result = PersistDataValueConfiguration(dataObject: config) else {
            XCTFail("Configuration should be created with default update policy when update_policy is invalid")
            return
        }
        XCTAssertEqual(result.updatePolicy, .allowUpdate)
    }

    private func makeConfiguration(
        expiryPolicy: ExpiryPolicy,
        updatePolicy: UpdatePolicy = .allowUpdate
    ) -> PersistDataValueConfiguration {
        PersistDataValueConfiguration(
            destination: .key("test_dest"),
            input: .reference(.key("test_source")),
            expiryPolicy: expiryPolicy,
            updatePolicy: updatePolicy
        )
    }
}
