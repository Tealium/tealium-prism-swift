//
//  LifecycleModuleCollectorTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 25/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LifecycleModuleCollectorTests: LifecycleModuleBaseTests {
    func test_the_module_id_is_correct() {
        XCTAssertNotNil(dataStoreProvider.modulesRepository.getModules()[LifecycleModule.moduleType])
    }

    func test_collect_returns_empty_object_if_dataTarget_is_allEvents_and_dispatchContext_has_source_lifecycle() {
        updateSettings(LifecycleSettingsBuilder().setDataTarget(.allEvents))
        XCTAssertEqual(module.collect(lifecycleDispatchContext).count, 0)
    }

    func test_collect_returns_current_state_if_dataTarget_is_allEvents_and_dispatchContext_has_source_application() {
        updateSettings(LifecycleSettingsBuilder().setDataTarget(.allEvents))
        let applicationDispatchContext = DispatchContext(source: .application, initialData: Dispatch(name: "lifecycle").payload)
        XCTAssertNotEqual(module.collect(applicationDispatchContext).count, 0)
    }

    func test_collect_returns_empty_object_if_dataTarget_is_lifecycleEventsOnly() {
        XCTAssertEqual(module.collect(lifecycleDispatchContext).count, 0)
    }
}
