//
//  PersistDataValueSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 19/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class PersistDataValueSettingsBuilderTests: XCTestCase {

    let transformationId = "test-transformation"

    func test_constructor_sets_correct_ids() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId).build()
        XCTAssertEqual(settings.id, transformationId)
        XCTAssertEqual(settings.transformerId, Modules.Types.persistDataValueTransformer)
    }

    func test_persist_with_constant_input_sets_configuration() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persist(input: "constant_value", destination: .key("dest_key"))
            .build()
        guard let config = PersistDataValueConfiguration(dataObject: settings.configuration) else {
            XCTFail("Expected valid configuration")
            return
        }
        guard case .constant(let value) = config.input else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(value.value.get(), "constant_value")
        XCTAssertEqual(config.destination, .key("dest_key"))
    }

    func test_persist_with_reference_input_sets_configuration() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persist(input: .key("source_key"), destination: .key("dest_key"))
            .build()
        guard let config = PersistDataValueConfiguration(dataObject: settings.configuration) else {
            XCTFail("Expected valid configuration")
            return
        }
        guard case .reference(let ref) = config.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("source_key"))
        XCTAssertEqual(config.destination, .key("dest_key"))
    }

    func test_setExpiryPolicy_sets_configuration() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persist(input: "value", destination: .key("dest"))
            .setExpiryPolicy(.forever)
            .build()
        guard let config = PersistDataValueConfiguration(dataObject: settings.configuration) else {
            XCTFail("Expected valid configuration")
            return
        }
        XCTAssertEqual(config.expiryPolicy, .forever)
    }

    func test_setUpdatePolicy_sets_configuration() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persist(input: "value", destination: .key("dest"))
            .setUpdatePolicy(.keepFirstValue)
            .build()
        guard let config = PersistDataValueConfiguration(dataObject: settings.configuration) else {
            XCTFail("Expected valid configuration")
            return
        }
        XCTAssertEqual(config.updatePolicy, .keepFirstValue)
    }

    func test_default_values() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persist(input: "value", destination: .key("dest"))
            .build()
        guard let config = PersistDataValueConfiguration(dataObject: settings.configuration) else {
            XCTFail("Expected valid configuration")
            return
        }
        XCTAssertEqual(config.expiryPolicy, .session)
        XCTAssertEqual(config.updatePolicy, .allowUpdate)
    }

    func test_build_with_no_input_or_destination_produces_nil() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId).build()
        let config = PersistDataValueConfiguration(dataObject: settings.configuration)
        XCTAssertNil(config)
    }

    func test_build_with_all_properties_produces_complete_configuration() {
        let condition = Rule<Condition>.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test"))
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persist(input: .key("source"), destination: .key("dest"))
            .setExpiryPolicy(.forever)
            .setUpdatePolicy(.keepFirstValue)
            .addScope(.afterCollectors)
            .setConditions(condition)
            .build()

        XCTAssertEqual(settings.id, transformationId)
        XCTAssertEqual(settings.transformerId, Modules.Types.persistDataValueTransformer)
        XCTAssertTrue(settings.scopes.contains(.afterCollectors))
        XCTAssertNotNil(settings.conditions)

        guard let config = PersistDataValueConfiguration(dataObject: settings.configuration) else {
            XCTFail("Expected valid configuration")
            return
        }
        guard case .reference(let ref) = config.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("source"))
        XCTAssertEqual(config.destination, .key("dest"))
        XCTAssertEqual(config.expiryPolicy, .forever)
        XCTAssertEqual(config.updatePolicy, .keepFirstValue)
    }

    func test_persist_with_constant_input_returns_builder() {
        let builder = PersistDataValueSettingsBuilder(id: transformationId)
        let result = builder.persist(input: "value", destination: .key("dest"))
        XCTAssertTrue(result === builder)
    }

    func test_persist_with_reference_input_returns_builder() {
        let builder = PersistDataValueSettingsBuilder(id: transformationId)
        let result = builder.persist(input: .key("source"), destination: .key("dest"))
        XCTAssertTrue(result === builder)
    }

    func test_setExpiryPolicy_returns_builder() {
        let builder = PersistDataValueSettingsBuilder(id: transformationId)
        let result = builder.setExpiryPolicy(.session)
        XCTAssertTrue(result === builder)
    }

    func test_setUpdatePolicy_returns_builder() {
        let builder = PersistDataValueSettingsBuilder(id: transformationId)
        let result = builder.setUpdatePolicy(.allowUpdate)
        XCTAssertTrue(result === builder)
    }
}
