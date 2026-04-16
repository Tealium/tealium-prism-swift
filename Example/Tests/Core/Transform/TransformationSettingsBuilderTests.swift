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
        let dataObject = TransformationSettingsBuilder(id: id, transformerId: transformerId).build()
        XCTAssertEqual(dataObject.get(key: TransformationSettings.Keys.id), id)
        XCTAssertEqual(dataObject.get(key: TransformationSettings.Keys.transformerId), transformerId)
    }

    func test_build_with_only_required_fields_omits_other_keys() {
        let dataObject = TransformationSettingsBuilder(id: id, transformerId: transformerId).build()
        XCTAssertFalse(dataObject.keys.contains(TransformationSettings.Keys.scopes))
        XCTAssertFalse(dataObject.keys.contains(TransformationSettings.Keys.conditions))
        XCTAssertFalse(dataObject.keys.contains(TransformationSettings.Keys.configuration))
    }

    func test_setConfiguration_sets_configuration_value() {
        let config: DataObject = ["some_key": "some_value"]
        let dataObject = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            ._setConfiguration(config)
            .build()
        XCTAssertEqual(dataObject.getDataDictionary(key: TransformationSettings.Keys.configuration)?.toDataObject(), config)
    }

    func test_setConfiguration_sets_nothing_when_configuration_empty() {
        let config: DataObject = [:]
        let dataObject = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            ._setConfiguration(config)
            .build()
        XCTAssertFalse(dataObject.keys.contains(TransformationSettings.Keys.configuration))
    }

    func test_setConditions_sets_conditions_value() {
        let condition = Rule<Condition>.just(Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test"))
        let expectedConditions: DataObject = [
            "operator": "equals",
            "variable": ["key": "tealium_event"],
            "filter": ["value": "test"]
        ]
        let dataObject = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            .setConditions(condition)
            .build()
        XCTAssertEqual(dataObject.getDataDictionary(key: TransformationSettings.Keys.conditions)?.toDataObject(), expectedConditions)
    }

    func test_setScopes_and_addScope_set_scopes_value() {
        let dataObject = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            .setScopes([.afterCollectors, .allDispatchers])
            .addScope(.dispatcher(id: "Disp1"))
            .build()
        XCTAssertEqual(dataObject.getArray(key: TransformationSettings.Keys.scopes), ["aftercollectors", "alldispatchers", "Disp1"])
    }

    func test_setScopes_with_empty_array_after_addScope_removes_scopes_key() {
        let builder = TransformationSettingsBuilder(id: id, transformerId: transformerId)
            .addScope(.afterCollectors)
        XCTAssertTrue(builder.build().keys.contains(TransformationSettings.Keys.scopes))

        _ = builder.setScopes([])
        XCTAssertFalse(builder.build().keys.contains(TransformationSettings.Keys.scopes))
    }
}
