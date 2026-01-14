//
//  ModulesTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class NonDisableableModule: BasicModule {
    static let moduleType: String = "non-disableable"
    var id: String { Self.moduleType }
    static let canBeDisabled: Bool = false

    let version: String = "1.0.0"
    required init?(context: TealiumContext,
                   moduleConfiguration: DataObject) {
    }
}

final class ModulesTests: XCTestCase {
    let nonDisableableFactory = BasicModuleFactory<NonDisableableModule>(moduleType: NonDisableableModule.moduleType)
    let disableableFactory = MockDispatcher1.factory()
    func test_shouldBeEnabled_on_NonDisableableModule_returns_true_for_settings_enabled() {
        XCTAssertTrue(nonDisableableFactory.shouldBeEnabled(by: ModuleSettings(moduleType: NonDisableableModule.moduleType,
                                                                               enabled: true)))
    }

    func test_shouldBeEnabled_on_NonDisableableModule_returns_true_for_settings_disabled() {
        XCTAssertTrue(nonDisableableFactory.shouldBeEnabled(by: ModuleSettings(moduleType: NonDisableableModule.moduleType,
                                                                               enabled: false)))
    }

    func test_shouldBeEnabled_on_NonDisableableModule_returns_true_for_settings_without_enabled_key() {
        XCTAssertTrue(nonDisableableFactory.shouldBeEnabled(by: ModuleSettings(moduleType: NonDisableableModule.moduleType)))
    }

    func test_shouldBeEnabled_on_DisableableModule_returns_true_for_settings_enabled() {
        XCTAssertTrue(disableableFactory.shouldBeEnabled(by: ModuleSettings(moduleType: NonDisableableModule.moduleType,
                                                                            enabled: true)))
    }

    func test_shouldBeEnabled_on_DisableableModule_returns_false_for_settings_disabled() {
        XCTAssertFalse(disableableFactory.shouldBeEnabled(by: ModuleSettings(moduleType: NonDisableableModule.moduleType,
                                                                             enabled: false)))
    }

    func test_shouldBeEnabled_on_DisableableModule_returns_true_for_settings_without_enabled_key() {
        XCTAssertTrue(disableableFactory.shouldBeEnabled(by: ModuleSettings(moduleType: NonDisableableModule.moduleType)))
    }
}
