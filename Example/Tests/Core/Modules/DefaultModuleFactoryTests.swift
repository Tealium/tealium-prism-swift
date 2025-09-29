//
//  DefaultModuleFactoryTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class CustomModule: BasicModule {
    var id: String { Self.moduleType }

    @StateSubject<DataObject>([:])
    var moduleConfiguration: ObservableState<DataObject>
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        _moduleConfiguration.value = moduleConfiguration
    }

    static let moduleType: String = "CustomModule"

    let version: String = "1.0.0"

    func updateConfiguration(_ configuration: DataObject) -> Self? {
        _moduleConfiguration.value = configuration
        return self
    }

}

final class DefaultModuleFactoryTests: XCTestCase {
    func test_getEnforcedSettings_returns_settings_built_in_the_init() {
        let settings: DataObject = ["key": "value"]
        let factory = DefaultModuleFactory<CustomModule>(moduleType: CustomModule.moduleType, enforcedSettings: settings)
        XCTAssertEqual(factory.getEnforcedSettings(), [settings])
    }

    func test_create_initializes_module_with_provided_configuration() {
        let configuration: DataObject = ["key": "value"]
        let factory = DefaultModuleFactory<CustomModule>(moduleType: CustomModule.moduleType)
        let module = factory.create(moduleId: MockModule.moduleType,
                                    context: mockContext,
                                    moduleConfiguration: configuration)
        XCTAssertEqual(module?.moduleConfiguration.value, configuration)
    }
}
