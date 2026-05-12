//
//  BarrierSettingsBuilderTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 09/01/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class BarrierSettingsBuilderTests: XCTestCase {

    func test_setScope_all_sets_scope_string() {
        let result = BarrierSettingsBuilder().setScope(.all).build()
        XCTAssertEqual(result.get(key: BarrierSettings.Keys.scope), "all")
    }

    func test_setScope_dispatchers_sets_scope_array() {
        let result = BarrierSettingsBuilder().setScope(.dispatchers(["collect", "trace"])).build()
        XCTAssertEqual(result.getArray(key: BarrierSettings.Keys.scope), ["collect", "trace"])
    }

    func test_setScope_empty_dispatchers_sets_empty_array() {
        let result = BarrierSettingsBuilder().setScope(.dispatchers([])).build()
        XCTAssertEqual(result.getArray(key: BarrierSettings.Keys.scope, of: String.self), [])
    }

    func test_build_includes_configuration_object() {
        let builder = BarrierSettingsBuilder()
        builder._configurationObject = ["custom_key": "custom_value"]
        let result = builder.build()

        let configuration = result.getDataDictionary(key: BarrierSettings.Keys.configuration)
        XCTAssertEqual(configuration?.get(key: "custom_key"), "custom_value")
    }

    func test_build_with_empty_builder_returns_minimal_structure() {
        let result = BarrierSettingsBuilder().build()

        XCTAssertTrueOptional(result.getDataDictionary(key: BarrierSettings.Keys.configuration)?.keys.isEmpty)
        XCTAssertNil(result.get(key: BarrierSettings.Keys.barrierId, as: String.self))
        XCTAssertNil(result.get(key: BarrierSettings.Keys.scope, as: String.self))
    }
}
