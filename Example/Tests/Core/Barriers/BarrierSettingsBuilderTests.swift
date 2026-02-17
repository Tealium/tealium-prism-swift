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

    func test_setScopes_sets_scopes_array() {
        let builder = BarrierSettingsBuilder()
        let scopes: [BarrierScope] = [.all, .dispatcher(id: "test-dispatcher")]
        let result = builder.setScopes(scopes).build()

        XCTAssertEqual(result.getArray(key: BarrierSettings.Keys.scopes), ["all", "test-dispatcher"])
    }

    func test_setScopes_with_empty_array() {
        let builder = BarrierSettingsBuilder()
        let result = builder.setScopes([]).build()

        let resultScopes = result.getArray(key: BarrierSettings.Keys.scopes, of: String.self)
        XCTAssertEqual(resultScopes, [])
    }

    func test_build_includes_configuration_object() {
        let builder = BarrierSettingsBuilder()
        builder._configurationObject = ["custom_key": "custom_value"]
        let result = builder.build()

        let configuration = result.getDataDictionary(key: BarrierSettings.Keys.configuration)
        XCTAssertEqual(configuration?.get(key: "custom_key", as: String.self), "custom_value")
    }

    func test_build_with_empty_builder_returns_minimal_structure() {
        let builder = BarrierSettingsBuilder()
        let result = builder.build()

        XCTAssertTrueOptional(result.getDataDictionary(key: BarrierSettings.Keys.configuration)?.isEmpty)
        XCTAssertNil(result.get(key: BarrierSettings.Keys.barrierId, as: String.self))
        XCTAssertNil(result.getArray(key: BarrierSettings.Keys.scopes, of: String.self))
    }
}
