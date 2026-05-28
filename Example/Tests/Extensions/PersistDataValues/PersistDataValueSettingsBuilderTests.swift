//
//  PersistDataValueSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 19/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class PersistDataValueSettingsBuilderTests: ExtensionsBaseTests {

    let transformationId = "test-transformation"

    func test_constructor_sets_correct_ids() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId).build()
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.id), transformationId)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.transformerId), Modules.Types.persistDataValueTransformer)
    }

    func test_persistConstant_sets_input_key() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistConstant("constant_value", to: .key("dest_key"))
            .build()
        guard case .constant(let value) = extractInput(from: settings) else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(value.value.get(), "constant_value")
    }

    func test_persistConstant_sets_destination_key() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistConstant("constant_value", to: .key("dest_key"))
            .build()
        XCTAssertEqual(extractDestination(from: settings), .key("dest_key"))
    }

    func test_persistFrom_sets_input_key() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistFrom(.key("source_key"), to: .key("dest_key"))
            .build()
        guard case .reference(let ref) = extractInput(from: settings) else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("source_key"))
    }

    func test_persistFrom_sets_destination_key() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistFrom(.key("source_key"), to: .key("dest_key"))
            .build()
        XCTAssertEqual(extractDestination(from: settings), .key("dest_key"))
    }

    func test_setExpiryPolicy_sets_duration_key() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistConstant("value", to: .key("dest"))
            .setExpiryPolicy(.forever)
            .build()
        let duration = configDataObject(from: settings)
            .getConvertible(key: PersistDataValueConfiguration.Keys.duration, converter: ExpiryPolicy.converter)
        XCTAssertEqual(duration, .forever)
    }

    func test_setUpdatePolicy_sets_updatePolicy_key() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistConstant("value", to: .key("dest"))
            .setUpdatePolicy(.keepFirstValue)
            .build()
        let rawValue: String? = configDataObject(from: settings)
            .get(key: PersistDataValueConfiguration.Keys.updatePolicy)
        XCTAssertEqual(rawValue, UpdatePolicy.keepFirstValue.rawValue)
    }

    func test_build_without_setExpiryPolicy_omits_duration_key() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistConstant("value", to: .key("dest"))
            .build()
        XCTAssertFalse(configDataObject(from: settings).keys.contains(PersistDataValueConfiguration.Keys.duration))
    }

    func test_build_without_setUpdatePolicy_omits_updatePolicy_key() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistConstant("value", to: .key("dest"))
            .build()
        XCTAssertFalse(configDataObject(from: settings).keys.contains(PersistDataValueConfiguration.Keys.updatePolicy))
    }

    func test_build_with_no_input_omits_input_key_from_config() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId).build()
        XCTAssertFalse(configDataObject(from: settings).keys.contains(PersistDataValueConfiguration.Keys.input))
    }

    func test_build_with_no_destination_omits_destination_key_from_config() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId).build()
        XCTAssertFalse(configDataObject(from: settings).keys.contains(PersistDataValueConfiguration.Keys.destination))
    }

    func test_build_with_all_properties() {
        let condition = Rule<Condition>.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test"))
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistFrom(.key("source"), to: .key("dest"))
            .setExpiryPolicy(.forever)
            .setUpdatePolicy(.keepFirstValue)
            .setScope(.afterCollectors)
            .setConditions(condition)
            .build()

        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.id), transformationId)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.transformerId), Modules.Types.persistDataValueTransformer)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.scope), "aftercollectors")
        XCTAssertNotNil(settings.getDataDictionary(key: TransformationSettings.Keys.conditions))

        guard case .reference(let ref) = extractInput(from: settings) else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("source"))
        XCTAssertEqual(extractDestination(from: settings), .key("dest"))

        let duration = configDataObject(from: settings)
            .getConvertible(key: PersistDataValueConfiguration.Keys.duration, converter: ExpiryPolicy.converter)
        XCTAssertEqual(duration, .forever)

        let rawUpdatePolicy: String? = configDataObject(from: settings)
            .get(key: PersistDataValueConfiguration.Keys.updatePolicy)
        XCTAssertEqual(rawUpdatePolicy, UpdatePolicy.keepFirstValue.rawValue)
    }

    func test_persistConstant_returns_builder() {
        let builder = PersistDataValueSettingsBuilder(id: transformationId)
        let result = builder.persistConstant("value", to: .key("dest"))
        XCTAssertTrue(result === builder)
    }

    func test_persistFrom_returns_builder() {
        let builder = PersistDataValueSettingsBuilder(id: transformationId)
        let result = builder.persistFrom(.key("source"), to: .key("dest"))
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

    func test_persistFrom_after_persistConstant_overwrites_input() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistConstant("constant", to: .key("dest1"))
            .persistFrom(.key("source"), to: .key("dest2"))
            .build()
        guard case .reference(let ref) = extractInput(from: settings) else {
            XCTFail("Expected reference input"); return
        }
        XCTAssertEqual(ref, .key("source"))
        XCTAssertEqual(extractDestination(from: settings), .key("dest2"))
    }

    func test_persistConstant_after_persistFrom_overwrites_input() {
        let settings = PersistDataValueSettingsBuilder(id: transformationId)
            .persistFrom(.key("source"), to: .key("dest1"))
            .persistConstant("constant", to: .key("dest2"))
            .build()
        guard case .constant(let value) = extractInput(from: settings) else {
            XCTFail("Expected constant input"); return
        }
        XCTAssertEqual(value.value.get(), "constant")
        XCTAssertEqual(extractDestination(from: settings), .key("dest2"))
    }

    private func extractInput(from settings: DataObject) -> ValueSource? {
        configDataObject(from: settings)
            .getConvertible(key: PersistDataValueConfiguration.Keys.input, converter: ValueSource.converter)
    }

    private func extractDestination(from settings: DataObject) -> ReferenceContainer? {
        configDataObject(from: settings)
            .getConvertible(key: PersistDataValueConfiguration.Keys.destination, converter: ReferenceContainer.converter)
    }
}
