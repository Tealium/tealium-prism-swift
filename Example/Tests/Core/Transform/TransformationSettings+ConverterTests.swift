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

    func test_transformation_to_data_object() {
        // Test DataObjectConvertible implementation
        let condition = Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test_event")
        let configuration: DataObject = ["key1": "value1", "key2": 123]
        let transformation = TransformationSettings(id: "test_id",
                                                    transformerId: "test_transformer",
                                                    scopes: [.afterCollectors, .dispatcher(id: "test_dispatcher")],
                                                    configuration: configuration,
                                                    conditions: .just(condition))

        let dataObject = transformation.toDataObject()

        XCTAssertEqual(dataObject.get(key: TransformationSettings.Keys.id), "test_id")
        XCTAssertEqual(dataObject.get(key: TransformationSettings.Keys.transformerId), "test_transformer")

        let scopesArray = dataObject.getArray(key: TransformationSettings.Keys.scopes, of: String.self)
        XCTAssertEqual(scopesArray?.count, 2)
        XCTAssertTrueOptional(scopesArray?.contains("aftercollectors"))
        XCTAssertTrueOptional(scopesArray?.contains("test_dispatcher"))

        let configObject = dataObject.getDataDictionary(key: TransformationSettings.Keys.configuration)
        XCTAssertEqual(configObject?.get(key: "key1", as: String.self), "value1")
        XCTAssertEqual(configObject?.get(key: "key2", as: Int.self), 123)

        XCTAssertEqual(dataObject.getDataDictionary(key: TransformationSettings.Keys.conditions)?.toDataObject(), testCondition)
    }

    func test_transformation_converter_with_configuration_returns_transformation_with_configuration() {
        // Test DataItemConverter implementation
        let id = "test_id"
        let transformerId = "test_transformer"
        let scopes = ["aftercollectors", "test_dispatcher"]
        let configuration: DataObject = ["key1": "value1", "key2": 123]

        // Create a DataItem that represents a TransformationSettings
        let settings: DataObject = [
            TransformationSettings.Keys.id: id,
            TransformationSettings.Keys.transformerId: transformerId,
            TransformationSettings.Keys.scopes: scopes,
            TransformationSettings.Keys.configuration: configuration
        ]

        // Convert using the converter
        let transformation = TransformationSettings.converter.convert(dataItem: settings.toDataItem())

        // Verify the conversion
        XCTAssertNotNil(transformation)
        XCTAssertEqual(transformation?.id, id)
        XCTAssertEqual(transformation?.transformerId, transformerId)
        XCTAssertEqual(transformation?.scopes.count, 2)
        XCTAssertTrueOptional(transformation?.scopes.contains(.afterCollectors))
        XCTAssertTrueOptional(transformation?.scopes.contains(.dispatcher(id: "test_dispatcher")))
        XCTAssertEqual(transformation?.configuration.get(key: "key1", as: String.self), "value1")
        XCTAssertEqual(transformation?.configuration.get(key: "key2", as: Int.self), 123)
        XCTAssertNil(transformation?.conditions)
    }

    func test_transformation_converter_with_conditions_returns_transformation_with_condition() {
        let settings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scopes: ["aftercollectors"],
            TransformationSettings.Keys.conditions: testCondition
        ]
        let expectedRule = Rule.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test_event"))

        // Convert using the converter
        let transformation: TransformationSettings? = settings.getConvertible(converter: TransformationSettings.converter)

        // Verify the conversion
        XCTAssertNotNil(transformation)
        XCTAssertNotNil(transformation?.conditions)
        XCTAssertEqual(transformation?.configuration, [:])
        XCTAssertTrueOptional(transformation?.conditions?.equals(expectedRule))
    }

    func test_transformation_converter_with_invalid_data_returns_nil() {
        // Test with missing required fields
        let missingIdSettings: DataObject = [
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scopes: ["aftercollectors"]
        ]
        let missingIdItem = missingIdSettings.toDataItem()
        XCTAssertNil(TransformationSettings.converter.convert(dataItem: missingIdItem))

        let missingTransformerIdSettings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.scopes: ["aftercollectors"]
        ]
        let missingTransformerIdItem = missingTransformerIdSettings.toDataItem()
        XCTAssertNil(TransformationSettings.converter.convert(dataItem: missingTransformerIdItem))

        let missingScopesSettings: DataObject = [
            TransformationSettings.Keys.id: "test_id",
            TransformationSettings.Keys.transformerId: "test_transformer"
        ]
        let missingScopesItem = missingScopesSettings.toDataItem()
        XCTAssertNil(TransformationSettings.converter.convert(dataItem: missingScopesItem))

        // Test with wrong data types
        let wrongTypesSettings: DataObject = [
            TransformationSettings.Keys.id: 123, // Should be String
            TransformationSettings.Keys.transformerId: "test_transformer",
            TransformationSettings.Keys.scopes: ["aftercollectors"]
        ]
        let wrongTypesItem = wrongTypesSettings.toDataItem()
        XCTAssertNil(TransformationSettings.converter.convert(dataItem: wrongTypesItem))
    }
}
