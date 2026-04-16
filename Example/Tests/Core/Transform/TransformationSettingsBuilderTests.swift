//
//  TransformationSettingsBuilderTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 02/04/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TransformationSettingsBuilderTests: XCTestCase {

    let id = "test-id"
    let transformerId = "test-transformer"

    func test_build_sets_id_and_transformerId() {
        let settings = TransformationSettingsBuilder(id: id, transformerId: transformerId).build()
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.id), id)
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.transformerId), transformerId)
    }

    func test_build_with_only_required_fields_omits_other_keys() {
        let settings = TransformationSettingsBuilder(id: id, transformerId: transformerId).build()
        XCTAssertFalse(settings.keys.contains(TransformationSettings.Keys.scope))
        XCTAssertFalse(settings.keys.contains(TransformationSettings.Keys.conditions))
        XCTAssertFalse(settings.keys.contains(TransformationSettings.Keys.configuration))
    }

    func test_setConfiguration_sets_configuration_value() {
        let config: DataObject = ["some_key": "some_value"]
        let settings = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            ._setConfiguration(config)
            .build()
        XCTAssertEqual(settings.getDataDictionary(key: TransformationSettings.Keys.configuration)?.toDataObject(), config)
    }

    func test_setConfiguration_sets_nothing_when_configuration_empty() {
        let config: DataObject = [:]
        let settings = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            ._setConfiguration(config)
            .build()
        XCTAssertFalse(settings.keys.contains(TransformationSettings.Keys.configuration))
    }

    func test_setConditions_sets_conditions_value() {
        let condition = Rule<Condition>.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test"))
        let expectedConditions: DataObject = [
            "operator": "equals",
            "variable": ["key": "tealium_event"],
            "filter": ["value": "test"]
        ]
        let settings = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            .setConditions(condition)
            .build()
        XCTAssertEqual(settings.getDataDictionary(key: TransformationSettings.Keys.conditions)?.toDataObject(), expectedConditions)
    }

    func test_setScope_afterCollectors_sets_scope_string() {
        let settings = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            .setScope(.afterCollectors)
            .build()
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.scope), "aftercollectors")
    }

    func test_setScope_allDispatchers_sets_scope_string() {
        let settings = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            .setScope(.allDispatchers)
            .build()
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.scope), "alldispatchers")
    }

    func test_setScope_dispatchers_sets_scope_array() {
        let settings = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            .setScope(.dispatchers(["Collect", "Facebook"]))
            .build()
        XCTAssertEqual(settings.getArray(key: TransformationSettings.Keys.scope), ["Collect", "Facebook"])
    }

    func test_setScope_overwrites_previous_scope() {
        let settings = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            .setScope(.afterCollectors)
            .setScope(.allDispatchers)
            .build()
        XCTAssertEqual(settings.get(key: TransformationSettings.Keys.scope), "alldispatchers")
    }
}
