//
//  DispatchManager+MappingsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DispatchManagerMappingsTests: DispatchManagerTestCase {

    func addMappings(moduleType: String, mappings: [MappingOperation]) {
        let module = if let moduleSettings = sdkSettings.value.modules[moduleType] {
            ModuleSettings(moduleType: moduleType,
                           enabled: moduleSettings.enabled,
                           rules: moduleSettings.rules,
                           mappings: mappings,
                           configuration: moduleSettings.configuration)
        } else {
            ModuleSettings(moduleType: moduleType, mappings: mappings)
        }
        _sdkSettings.add(modules: [module.moduleId: module])
        modulesManager.updateSettings(context: context, settings: sdkSettings.value)
    }

    func test_mappings_are_applied_to_dispatcher() {
        let dispatchReceived = expectation(description: "Dispatcher received tracked dispatch")
        let mappings = Mappings()
        mappings.mapConstant("someConstant", to: "destination")
        addMappings(moduleType: MockDispatcher1.moduleType, mappings: mappings.build())
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertGreaterThan(dispatches.count, 0)
            for dispatch in dispatches {
                XCTAssertEqual(dispatch.payload, ["destination": "someConstant"])
            }
            dispatchReceived.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }

    func test_mappings_are_applied_after_transformations() {
        let dispatchReceived = expectation(description: "Dispatcher received tracked dispatch")
        let mappings = Mappings()
        mappings.mapFrom("transformation-\(MockDispatcher1.moduleType)",
                         to: "destination")
        addMappings(moduleType: MockDispatcher1.moduleType, mappings: mappings.build())
        module1?.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            XCTAssertNotNil(dispatches.first?.payload.getDataItem(key: "destination"))
            dispatchReceived.fulfill()
        }
        dispatchManager.track(Dispatch(name: "someEvent"))
        waitForDefaultTimeout()
    }
}
