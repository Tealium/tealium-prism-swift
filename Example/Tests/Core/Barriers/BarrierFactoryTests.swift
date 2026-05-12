//
//  BarrierFactoryTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 09/01/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

private struct MinimalBarrierFactory: BarrierFactory {
    func create(context: TealiumContext, configuration: DataObject) -> MockConfigurableBarrier {
        MockConfigurableBarrier()
    }
}

final class BarrierFactoryTests: XCTestCase {
    func test_default_getEnforcedSettings_returns_empty_data_object() {
        let factory = MockBarrierFactory(defaultScope: .all)
        XCTAssertEqual(factory.getEnforcedSettings(), [:])
    }

    func test_custom_getEnforcedSettings_returns_enforced_settings() {
        let settings: DataObject = ["test_key": "test_value"]
        let factory = MockBarrierFactory(defaultScope: .all, enforcedSettings: settings)

        XCTAssertEqual(factory.getEnforcedSettings(), settings)
    }

    func test_factory_id_matches_barrier_id() {
        let factory = MockBarrierFactory(defaultScope: .all)
        XCTAssertEqual(factory.id, MockConfigurableBarrier.id)
    }

    func test_extension_defaultScope_returns_all() {
        let factory = MinimalBarrierFactory()
        XCTAssertEqual(factory.defaultScope(), .all)
    }

    func test_extension_getEnforcedSettings_returns_empty_data_object() {
        let factory = MinimalBarrierFactory()
        XCTAssertEqual(factory.getEnforcedSettings(), [:])
    }
}
