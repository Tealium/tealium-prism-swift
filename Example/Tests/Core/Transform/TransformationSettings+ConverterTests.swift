//
//  TransformationSettings+ConverterTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 29/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TransformationSettingsConverterTests: XCTestCase {
    let testCondition: DataObject = [
        "operator": "equals",
        "variable": ["key": "tealium_event"],
        "filter": ["value": "test_event"]
    ]

    func test_transformation_converter_with_configuration_returns_transformation_with_configuration() {
        let id = "test_id"
        let transformerId = "test_transformer"
        let configuration: DataObject = ["key1": "value1", "key2": 123]

        let settings: DataObject = [
            TransformationSettings.Keys.id: id,
            TransformationSettings.Keys.transformerId: transformerId,
            TransformationSettings.Keys.scope: "aftercollectors",
            TransformationSettings.Keys.configuration: configuration
        ]

        let transformation = TransformationSettings.converter.convert(dataItem: settings.toDataItem())

        XCTAssertNotNil(transformation)
        XCTAssertEqual(transformation?.id, id)
        XCTAssertEqual(transformation?.transformerId, transformerId)
        XCTAssertEqual(transformation?.scope, .afterCollectors)
        XCTAssertEqual(transformation?.configuration.get(key: "key1"), "value1")
        XCTAssertEqual(transformation?.configuration.get(key: "key2"), 123)
        XCTAssertNil(transformation?.conditions)
    }

    func test_transformation_converter_deserializes_order() {
        let settings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scope: "aftercollectors",
            TransformationSettings.Keys.order: 7
        ]
        let transformation = TransformationSettings.converter.convert(dataItem: settings.toDataItem())
        XCTAssertEqual(transformation?.order, 7)
    }

    func test_transformation_converter_sets_maxInt_order_when_absent() {
        let settings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scope: "aftercollectors"
        ]
        let transformation = TransformationSettings.converter.convert(dataItem: settings.toDataItem())
        XCTAssertEqual(transformation?.order, Int.max)
    }

    func test_transformation_converter_with_wrong_order_type_defaults_to_maxInt() {
        let settings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scope: "aftercollectors",
            TransformationSettings.Keys.order: "not_a_number"
        ]
        let transformation = TransformationSettings.converter.convert(dataItem: settings.toDataItem())
        XCTAssertEqual(transformation?.order, Int.max)
    }

    func test_transformation_converter_with_multiple_dispatcher_ids_returns_dispatchers_scope() {
        let settings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scope: ["Collect", "Facebook"]
        ]

        let transformation = TransformationSettings.converter.convert(dataItem: settings.toDataItem())

        XCTAssertNotNil(transformation)
        XCTAssertEqual(transformation?.scope, .dispatchers(["Collect", "Facebook"]))
    }

    func test_transformation_converter_with_conditions_returns_transformation_with_condition() {
        let settings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scope: "aftercollectors",
            TransformationSettings.Keys.conditions: testCondition
        ]
        let expectedRule = Rule.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test_event"))

        let transformation: TransformationSettings? = settings.getConvertible(converter: TransformationSettings.converter)

        XCTAssertNotNil(transformation)
        XCTAssertNotNil(transformation?.conditions)
        XCTAssertEqual(transformation?.configuration, [:])
        XCTAssertTrueOptional(transformation?.conditions?.equals(expectedRule))
    }

    func test_transformation_converter_with_invalid_data_returns_nil() {
        let missingIdSettings: DataObject = [
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scope: "aftercollectors"
        ]
        let missingIdItem = missingIdSettings.toDataItem()
        XCTAssertNil(TransformationSettings.converter.convert(dataItem: missingIdItem))

        let missingTransformerIdSettings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.scope: "aftercollectors"
        ]
        let missingTransformerIdItem = missingTransformerIdSettings.toDataItem()
        XCTAssertNil(TransformationSettings.converter.convert(dataItem: missingTransformerIdItem))

        let missingScopeSettings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.transformerId: "test_transformer"
        ]
        let missingScopeItem = missingScopeSettings.toDataItem()
        XCTAssertNil(TransformationSettings.converter.convert(dataItem: missingScopeItem))

        let wrongTypesSettings: DataObject = [
            TransformationSettings.Keys.id: 123, // Should be String
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scope: "aftercollectors"
        ]
        let wrongTypesItem = wrongTypesSettings.toDataItem()
        XCTAssertNil(TransformationSettings.converter.convert(dataItem: wrongTypesItem))
    }
}
