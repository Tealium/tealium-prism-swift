//
//  LifecycleModuleCollectorTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 25/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class LifecycleModuleCollectorTests: LifecycleModuleBaseTests {
    func test_data_property_returns_current_state_if_dataTarget_is_allEvents() {
        _ = module.updateSettings(LifecycleSettingsBuilder().setDataTarget(.allEvents).build())
        XCTAssertNotEqual(module.data.count, 0)
    }

    func test_data_property_returns_empty_object_if_dataTarget_is_lifecycleEventsOnly() {
        XCTAssertEqual(module.data.count, 0)
    }
}
