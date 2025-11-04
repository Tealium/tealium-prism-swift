//
//  SettingsManager+TransformationsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 27/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SettingsManagerTransformationsTests: SettingsManagerTestCase {

    func test_transformations_are_merged_on_init() throws {
        config.bundle = Bundle(for: type(of: self))
        let condition = Condition.equals(ignoreCase: false, variable: "tealium_event", target: "test_event")
        config.setTransformation(TransformationSettings(id: "programmaticTransformation",
                                                        transformerId: "someTransformer",
                                                        scopes: [.allDispatchers],
                                                        configuration: ["someKey": "someValue"],
                                                        conditions: .just(condition)))
        let manager = try getManager()
        let sdkSettings = manager.settings.value
        guard let programmaticTransformation = sdkSettings.transformations.first(where: { $0.value.id == "programmaticTransformation" })?.value else {
            XCTFail("Programmatic transformation not found")
            return
        }
        XCTAssertEqual(programmaticTransformation.id, "programmaticTransformation")
        XCTAssertEqual(programmaticTransformation.transformerId, "someTransformer")
        XCTAssertEqual(programmaticTransformation.scopes, [.allDispatchers])
        XCTAssertEqual(programmaticTransformation.configuration, ["someKey": "someValue"])
        XCTAssertNotNil(programmaticTransformation.conditions)
        guard let conditions = programmaticTransformation.conditions,
              case let .just(programmaticCondition) = conditions else {
            XCTFail("Unexpected condition type \(String(describing: programmaticTransformation.conditions))")
            return
        }
        XCTAssertEqual(programmaticCondition, condition)
        guard let localTransformation = sdkSettings.transformations.first(where: { $0.value.id == "transformationId" })?.value else {
            XCTFail("Local transformation not found")
            return
        }
        XCTAssertEqual(localTransformation.id, "transformationId")
        XCTAssertEqual(localTransformation.transformerId, "transformerId")
        XCTAssertEqual(localTransformation.scopes, [.afterCollectors])
        XCTAssertEqual(localTransformation.configuration, ["key": "value"])
        XCTAssertNotNil(localTransformation.conditions)
        guard let conditions = localTransformation.conditions,
              case let .just(localCondition) = conditions else {
            XCTFail("Unexpected condition type \(String(describing: programmaticTransformation.conditions))")
            return
        }
        XCTAssertEqual(localCondition, Condition.equals(ignoreCase: false,
                                                        variable: JSONPath["container"]["pageName"],
                                                        target: "Home"))
    }

    func test_transformation_configurations_are_merged_on_init() throws {
        config.bundle = Bundle(for: type(of: self))
        config.setTransformation(TransformationSettings(id: "transformationId",
                                                        transformerId: "transformerId",
                                                        scopes: [.allDispatchers],
                                                        configuration: ["someKey": "someValue"]))
        let manager = try getManager()
        let sdkSettings = manager.settings.value
        guard let transformation = sdkSettings.transformations.first(where: { $0.value.id == "transformationId" })?.value else {
            XCTFail("Transformation not found")
            return
        }
        XCTAssertEqual(transformation.configuration,
                       [
                        "someKey": "someValue",
                        "key": "value"
                       ])
    }
}
