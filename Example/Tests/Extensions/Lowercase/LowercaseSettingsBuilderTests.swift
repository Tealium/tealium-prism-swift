//
//  LowercaseSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 06/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LowercaseSettingsBuilderTests: ExtensionsBaseTests {

    let transformationId = "test-transformation"

    func test_constructor_sets_correct_ids() {
        let settings = LowercaseSettingsBuilder(id: transformationId).build()
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.id), transformationId)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.transformerId), Modules.Types.lowercaseTransformer)
    }

    func test_lowercaseAllVariables_sets_allvariables_string_in_config() {
        let settings = LowercaseSettingsBuilder(id: transformationId)
            .lowercaseAllVariables()
            .build()
        let policy = configDataObject(from: settings).get(key: LowercaseConfiguration.Keys.variables, as: String.self)
        XCTAssertEqual(policy, LowercaseConfiguration.PolicyValue.allVariables)
    }

    func test_lowercaseVariables_sets_array_in_config() {
        let settings = LowercaseSettingsBuilder(id: transformationId)
            .lowercaseVariables([.key("email")])
            .build()
        let items = configDataObject(from: settings).getDataArray(key: LowercaseConfiguration.Keys.variables)
        let refs = items?.compactMap { $0.getConvertible(converter: ReferenceContainer.converter) }
        XCTAssertEqual(refs?.count, 1)
        XCTAssertEqual(refs?.first, .key("email"))
    }

    func test_lowercaseVariables_multiple_references() {
        let settings = LowercaseSettingsBuilder(id: transformationId)
            .lowercaseVariables([.key("email"), .key("name")])
            .build()
        let items = configDataObject(from: settings).getDataArray(key: LowercaseConfiguration.Keys.variables)
        let refs = items?.compactMap { $0.getConvertible(converter: ReferenceContainer.converter) }
        XCTAssertEqual(refs?.count, 2)
        XCTAssertEqual(refs?[0], .key("email"))
        XCTAssertEqual(refs?[1], .key("name"))
    }

    func test_build_without_policy_omits_policy_key_from_config() {
        let settings = LowercaseSettingsBuilder(id: transformationId).build()
        XCTAssertFalse(configDataObject(from: settings).keys.contains(LowercaseConfiguration.Keys.variables))
    }

    func test_lowercaseVariables_with_empty_array_includes_variables_key_in_config() {
        let settings = LowercaseSettingsBuilder(id: transformationId)
            .lowercaseVariables([])
            .build()
        let config = configDataObject(from: settings)
        XCTAssertTrue(config.keys.contains(LowercaseConfiguration.Keys.variables))
        let items = config.getDataArray(key: LowercaseConfiguration.Keys.variables)
        XCTAssertEqual(items?.count, 0)
    }

    func test_build_with_all_properties() {
        let condition = Rule<Condition>.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test"))
        let settings = LowercaseSettingsBuilder(id: transformationId)
            .lowercaseVariables([.key("email")])
            .setScope(.afterCollectors)
            .setConditions(condition)
            .build()
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.id), transformationId)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.transformerId), Modules.Types.lowercaseTransformer)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.scope), "aftercollectors")
        XCTAssertNotNil(settings.getDataDictionary(key: TransformationSettings.Keys.conditions))
        let items = configDataObject(from: settings).getDataArray(key: LowercaseConfiguration.Keys.variables)
        let refs = items?.compactMap { $0.getConvertible(converter: ReferenceContainer.converter) }
        XCTAssertEqual(refs?.count, 1)
        XCTAssertEqual(refs?.first, .key("email"))
    }

    func test_lowercaseAllVariables_after_lowercaseVariables_replaces_policy() {
        let settings = LowercaseSettingsBuilder(id: transformationId)
            .lowercaseVariables([.key("email")])
            .lowercaseAllVariables()
            .build()
        let policy = configDataObject(from: settings).get(key: LowercaseConfiguration.Keys.variables, as: String.self)
        XCTAssertEqual(policy, LowercaseConfiguration.PolicyValue.allVariables)
    }

    func test_lowercaseVariables_after_lowercaseAllVariables_replaces_policy() {
        let settings = LowercaseSettingsBuilder(id: transformationId)
            .lowercaseAllVariables()
            .lowercaseVariables([.key("email")])
            .build()
        let items = configDataObject(from: settings).getDataArray(key: LowercaseConfiguration.Keys.variables)
        let refs = items?.compactMap { $0.getConvertible(converter: ReferenceContainer.converter) }
        XCTAssertEqual(refs?.count, 1)
        XCTAssertEqual(refs?.first, .key("email"))
    }

    func test_lowercaseVariables_returns_builder() {
        let builder = LowercaseSettingsBuilder(id: transformationId)
        let result = builder.lowercaseVariables([.key("email")])
        XCTAssertTrue(result === builder)
    }

    func test_lowercaseAllVariables_returns_builder() {
        let builder = LowercaseSettingsBuilder(id: transformationId)
        let result = builder.lowercaseAllVariables()
        XCTAssertTrue(result === builder)
    }
}
