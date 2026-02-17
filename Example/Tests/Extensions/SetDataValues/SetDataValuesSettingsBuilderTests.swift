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
    let converter = TransformationOperation.converter(parametersConverter: SetDataValuesParameters.converter)

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

    func test_addOperation_withReference() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .addOperation(input: .key("input_key"), destination: .key("destination_key"))
            .build()
        let operations = convertedOperations(from: settings)
        XCTAssertEqual(operations.count, 1)
        XCTAssertEqual(operations.first?.destination, .key("destination_key"))
        guard case .reference(let ref) = operations.first?.parameters.input else {
            XCTFail("Expected reference input")
            return
        }
        XCTAssertEqual(ref, .key("input_key"))
    }

    func test_addOperation_withConstant() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .addOperation(input: ValueContainer(["key": "value"]), destination: .key("destination_key"))
            .build()
        let operations = convertedOperations(from: settings)
        XCTAssertEqual(operations.count, 1)
        XCTAssertEqual(operations.first?.destination, .key("destination_key"))
        guard case .constant(let value) = operations.first?.parameters.input else {
            XCTFail("Expected constant input")
            return
        }
        XCTAssertEqual(value.value.getDictionary(of: String.self), ["key": "value"])
    }

    func test_addOperation_multiple() {
        let settings = SetDataValuesSettingsBuilder(id: transformationId)
            .addOperation(input: .key("input1_key"), destination: .key("destination1_key"))
            .addOperation(input: ValueContainer("constant-value"), destination: .key("destination2_key"))
            .build()
        let operations = convertedOperations(from: settings)
        XCTAssertEqual(operations.count, 2)
        guard case .reference(let ref) = operations[0].parameters.input else {
            XCTFail("Expected reference input for first operation")
            return
        }
        XCTAssertEqual(ref, .key("input1_key"))
        guard case .constant(let value) = operations[1].parameters.input else {
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
            .addOperation(input: .key("input_key"), destination: .key("destination_key"))
            .build()
        XCTAssertEqual(settings.id, transformationId)
        XCTAssertEqual(settings.transformerId, Modules.Types.setDataValuesTransformer)
        XCTAssertTrue(settings.scopes.contains(.afterCollectors))
        XCTAssertNotNil(settings.conditions)
        let operations = convertedOperations(from: settings)
        XCTAssertEqual(operations.count, 1)
    }

    func test_addOperation_returnsBuilder() {
        let builder = SetDataValuesSettingsBuilder(id: transformationId)
        let result = builder.addOperation(input: .key("key"), destination: .key("dest"))
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

    private func convertedOperations(from settings: TransformationSettings) -> [TransformationOperation<SetDataValuesParameters>] {
        guard let items = settings.configuration.getDataArray(key: "operations") else {
            return []
        }
        return items.compactMap { $0.getConvertible(converter: converter) }
    }
}
