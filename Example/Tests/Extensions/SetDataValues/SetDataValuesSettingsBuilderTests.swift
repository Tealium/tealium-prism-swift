//
//  SetDataValuesSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SetDataValuesSettingsBuilderTests: XCTestCase {

    let transformationId = "test-transformation"

    func test_constructor_setsCorrectIds() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId).build()
        XCTAssertEqual(settings.id, transformationId)
        XCTAssertEqual(settings.transformerId, Modules.Types.setDataValuesTransformer)
    }

    func test_addScope_single() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .addScope(.afterCollectors)
            .build()
        XCTAssertTrue(settings.scopes.contains(.afterCollectors))
        XCTAssertEqual(settings.scopes.count, 1)
    }

    func test_addScope_multiple() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .addScope(.afterCollectors)
            .addScope(.allDispatchers)
            .build()
        XCTAssertTrue(settings.scopes.contains(.afterCollectors))
        XCTAssertTrue(settings.scopes.contains(.allDispatchers))
        XCTAssertEqual(settings.scopes.count, 2)
    }

    func test_setFrom() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .setFrom(.key("input_key"), to: .key("destination_key"))
            .build()
        let operations = convertedOperations(from: settings)
        XCTAssertEqual(operations.count, 1)
        XCTAssertEqual(operations.first?.destination, .key("destination_key"))
        guard case .reference(let ref) = operations.first?.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("input_key"))
    }

    func test_setConstant() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .setConstant(["key": "value"], to: .key("destination_key"))
            .build()
        let operations = convertedOperations(from: settings)
        XCTAssertEqual(operations.count, 1)
        XCTAssertEqual(operations.first?.destination, .key("destination_key"))
        guard case .constant(let value) = operations.first?.input else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(value.value.getDictionary(of: String.self), ["key": "value"])
    }

    func test_setFrom_and_setConstant_multiple() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .setFrom(.key("input1_key"), to: .key("destination1_key"))
            .setConstant("constant-value", to: .key("destination2_key"))
            .build()
        let operations = convertedOperations(from: settings)
        XCTAssertEqual(operations.count, 2)
        guard case .reference(let ref) = operations[0].input else {
            XCTFail("Expected reference input for first operation")
            return
        }
        XCTAssertEqual(ref, .key("input1_key"))
        guard case .constant(let value) = operations[1].input else {
            XCTFail("Expected constant input for second operation")
            return
        }
        XCTAssertEqual(value.value.get(), "constant-value")
    }

    func test_build_withNoOperations() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId).build()
        let operations = convertedOperations(from: settings)
        XCTAssertEqual(operations.count, 0)
    }

    func test_build_withAllProperties() {
        let condition = Rule<Condition>.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test"))
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .addScope(.afterCollectors)
            .setConditions(condition)
            .setFrom(.key("input_key"), to: .key("destination_key"))
            .build()
        XCTAssertEqual(settings.id, transformationId)
        XCTAssertEqual(settings.transformerId, Modules.Types.setDataValuesTransformer)
        XCTAssertTrue(settings.scopes.contains(.afterCollectors))
        XCTAssertNotNil(settings.conditions)
        let operations = convertedOperations(from: settings)
        XCTAssertEqual(operations.count, 1)
    }

    func test_setFrom_returnsBuilder() {
        let builder = SetDataValuesSettingsBuilder(id: transformationId)
        let result = builder.setFrom(.key("key"), to: .key("dest"))
        XCTAssertTrue(result === builder)
    }

    func test_setConstant_returnsBuilder() {
        let builder = SetDataValuesSettingsBuilder(id: transformationId)
        let result = builder.setConstant("constant", to: .key("dest"))
        XCTAssertTrue(result === builder)
    }

    func test_addScope_returnsBuilder() {
        let builder = SetDataValuesSettingsBuilder(id: transformationId)
        let result = builder.addScope(.afterCollectors)
        XCTAssertTrue(result === builder)
    }

    func test_setConditions_returnsBuilder() {
        let builder = SetDataValuesSettingsBuilder(id: transformationId)
        let condition = Rule<Condition>.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test"))
        let result = builder.setConditions(condition)
        XCTAssertTrue(result === builder)
    }

    private func convertedOperations(from settings: TransformationSettings) -> [SetDataValuesOperation] {
        guard let items = settings.configuration.getDataArray(key: "operations") else {
            return []
        }
        return items.compactMap {
            SetDataValuesOperation(dataObject: $0.getDataDictionary()?.toDataObject() ?? [:])
        }
    }
}
