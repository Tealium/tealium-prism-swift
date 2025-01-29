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
    func test_collect_returns_empty_object_if_dataTarget_is_allEvents_and_dispatchContext_has_source_lifecycle() {
        _ = module.updateSettings(LifecycleSettingsBuilder().setDataTarget(.allEvents).build())
        XCTAssertEqual(module.collect(lifecycleDispatchContext).count, 0)
    }

    func test_collect_returns_current_state_if_dataTarget_is_allEvents_and_dispatchContext_has_source_application() {
        _ = module.updateSettings(LifecycleSettingsBuilder().setDataTarget(.allEvents).build())
        let applicationDispatchContext = DispatchContext(source: .application, initialData: TealiumDispatch(name: "lifecycle").eventData)
        XCTAssertNotEqual(module.collect(applicationDispatchContext).count, 0)
    }

    func test_collect_returns_empty_object_if_dataTarget_is_lifecycleEventsOnly() {
        XCTAssertEqual(module.collect(lifecycleDispatchContext).count, 0)
    }
}
