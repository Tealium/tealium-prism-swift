//
//  DefaultModuleFactoryTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DefaultModuleFactoryTests: XCTestCase {
    func test_getEnforcedSettings_returns_settings_built_in_the_init() {
        let settings: DataObject = ["key": "value"]
        let factory = DefaultModuleFactory<MockModule>(enforcedSettings: settings)
        XCTAssertEqual(factory.getEnforcedSettings(), settings)
    }

    func test_create_initializes_module_with_provided_configuration() {
        let configuration: DataObject = ["key": "value"]
        let factory = DefaultModuleFactory<MockModule>()
        let module = factory.create(context: mockContext, moduleConfiguration: configuration)
        XCTAssertEqual(module?.moduleConfiguration.value, configuration)
    }
}
