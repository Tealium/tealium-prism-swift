//
//  SetDataValuesSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SetDataValuesSettingsBuilderTests: ExtensionsBaseTests {

    let transformationId = "test-transformation"

    func test_constructor_setsCorrectIds() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId).build()
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.id), transformationId)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.transformerId), Modules.Types.setDataValuesTransformer)
    }

    func test_addScope_single() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .addScope(.afterCollectors)
            .build()
        XCTAssertEqual(settings.getArray(key: TransformationSettings.Keys.scopes), ["aftercollectors"])
    }

    func test_addScope_multiple() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .addScope(.afterCollectors)
            .addScope(.allDispatchers)
            .build()
        XCTAssertEqual(settings.getArray(key: TransformationSettings.Keys.scopes), ["aftercollectors", "alldispatchers"])
    }

    func test_setFrom_sets_reference_input() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .setFrom(.key("input_key"), to: .key("destination_key"))
            .build()
        let ops = operationDataObjects(from: settings)
        XCTAssertEqual(ops.count, 1)
        guard case .reference(let ref) = extractInput(from: ops[0]) else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("input_key"))
    }

    func test_setFrom_sets_destination() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .setFrom(.key("input_key"), to: .key("destination_key"))
            .build()
        let ops = operationDataObjects(from: settings)
        XCTAssertEqual(ops.count, 1)
        XCTAssertEqual(extractDestination(from: ops[0]), .key("destination_key"))
    }

    func test_setConstant_sets_constant_input() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .setConstant(["key": "value"], to: .key("destination_key"))
            .build()
        let ops = operationDataObjects(from: settings)
        XCTAssertEqual(ops.count, 1)
        guard case .constant(let value) = extractInput(from: ops[0]) else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(value.value.getDictionary(of: String.self), ["key": "value"])
    }

    func test_setConstant_sets_destination() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .setConstant(["key": "value"], to: .key("destination_key"))
            .build()
        let ops = operationDataObjects(from: settings)
        XCTAssertEqual(ops.count, 1)
        XCTAssertEqual(extractDestination(from: ops[0]), .key("destination_key"))
    }

    func test_setFrom_and_setConstant_multiple_produces_two_operations() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .setFrom(.key("input1_key"), to: .key("destination1_key"))
            .setConstant("constant-value", to: .key("destination2_key"))
            .build()
        let ops = operationDataObjects(from: settings)
        XCTAssertEqual(ops.count, 2)
        guard case .reference(let ref) = extractInput(from: ops[0]) else {
            XCTFail("Expected reference input for first operation")
            return
        }
        XCTAssertEqual(ref, .key("input1_key"))
        guard case .constant(let value) = extractInput(from: ops[1]) else {
            XCTFail("Expected constant input for second operation")
            return
        }
        XCTAssertEqual(value.value.get(), "constant-value")
    }

    func test_build_withNoOperations_omits_operations_key() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId).build()
        XCTAssertFalse(configDataObject(from: settings).keys.contains(SetDataValuesConfiguration.Keys.operations))
    }

    func test_build_withAllProperties() {
        let condition = Rule<Condition>.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test"))
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .addScope(.afterCollectors)
            .setConditions(condition)
            .setFrom(.key("input_key"), to: .key("destination_key"))
            .build()
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.id), transformationId)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.transformerId), Modules.Types.setDataValuesTransformer)
        XCTAssertEqual(settings.getArray(key: TransformationSettings.Keys.scopes), ["aftercollectors"])
        XCTAssertNotNil(settings.getDataDictionary(key: TransformationSettings.Keys.conditions))
        XCTAssertEqual(operationDataObjects(from: settings).count, 1)
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

    private func operationDataObjects(from settings: DataObject) -> [DataObject] {
        guard let items = configDataObject(from: settings)
            .getDataArray(key: SetDataValuesConfiguration.Keys.operations) else {
            return []
        }
        return items.compactMap { $0.getDataDictionary()?.toDataObject() }
    }

    private func extractInput(from operation: DataObject) -> ValueSource? {
        operation
            .getConvertible(key: SetDataValuesOperation.Keys.input, converter: ValueSource.converter)
    }

    private func extractDestination(from operation: DataObject) -> ReferenceContainer? {
        operation
            .getConvertible(key: SetDataValuesOperation.Keys.destination, converter: ReferenceContainer.converter)
    }
}
