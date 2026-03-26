//
//  LowerCaseSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 06/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LowerCaseSettingsBuilderTests: XCTestCase {

    let transformationId = "test-transformation"

    func test_constructor_sets_correct_ids() {
        let settings = LowerCaseSettingsBuilder(id: transformationId).build()
        XCTAssertEqual(settings.id, transformationId)
        XCTAssertEqual(settings.transformerId, Modules.Types.lowerCaseTransformer)
    }

    func test_setAllVariables_sets_value_in_config() {
        let settings = LowerCaseSettingsBuilder(id: transformationId)
            .setAllVariables(false)
            .build()
        let allVariables = settings.configuration.get(key: LowerCaseConfiguration.Keys.allVariables, as: Bool.self)
        XCTAssertEqual(allVariables, false)
    }

    func test_build_defaults_to_allVariables_true() {
        let settings = LowerCaseSettingsBuilder(id: transformationId).build()
        let config = LowerCaseConfiguration(dataObject: settings.configuration)
        XCTAssertEqual(config.allVariables, true)
    }

    func test_addVariable_adds_input_to_config() {
        let settings = LowerCaseSettingsBuilder(id: transformationId)
            .addVariable(.key("email"))
            .build()
        let inputs = convertedInputs(from: settings)
        XCTAssertEqual(inputs.count, 1)
        XCTAssertEqual(inputs.first, .key("email"))
    }

    func test_addVariable_multiple() {
        let settings = LowerCaseSettingsBuilder(id: transformationId)
            .addVariable(.key("email"))
            .addVariable(.key("name"))
            .build()
        let inputs = convertedInputs(from: settings)
        XCTAssertEqual(inputs.count, 2)
        XCTAssertEqual(inputs[0], .key("email"))
        XCTAssertEqual(inputs[1], .key("name"))
    }

    func test_build_with_no_inputs() {
        let settings = LowerCaseSettingsBuilder(id: transformationId).build()
        let inputs = convertedInputs(from: settings)
        XCTAssertEqual(inputs.count, 0)
    }

    func test_build_with_all_properties() {
        let condition = Rule<Condition>.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test"))
        let settings = LowerCaseSettingsBuilder(id: transformationId)
            .setAllVariables(false)
            .addVariable(.key("email"))
            .addScope(.afterCollectors)
            .setConditions(condition)
            .build()
        XCTAssertEqual(settings.id, transformationId)
        XCTAssertEqual(settings.transformerId, Modules.Types.lowerCaseTransformer)
        XCTAssertTrue(settings.scopes.contains(.afterCollectors))
        XCTAssertNotNil(settings.conditions)
        let allVariables = settings.configuration.get(key: LowerCaseConfiguration.Keys.allVariables, as: Bool.self)
        XCTAssertEqual(allVariables, false)
        let inputs = convertedInputs(from: settings)
        XCTAssertEqual(inputs.count, 1)
    }

    func test_addVariable_returns_builder() {
        let builder = LowerCaseSettingsBuilder(id: transformationId)
        let result = builder.addVariable(.key("email"))
        XCTAssertTrue(result === builder)
    }

    func test_setAllVariables_returns_builder() {
        let builder = LowerCaseSettingsBuilder(id: transformationId)
        let result = builder.setAllVariables(false)
        XCTAssertTrue(result === builder)
    }

    private func convertedInputs(from settings: TransformationSettings) -> [ReferenceContainer] {
        guard let items = settings.configuration.getDataArray(key: LowerCaseConfiguration.Keys.inputs) else {
            return []
        }
        return items.compactMap { $0.getConvertible(converter: ReferenceContainer.converter) }
    }
}
