//
//  TealiumModulesTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest
class NonDisableableModule: TealiumBasicModule {
    required init?(context: TealiumContext, moduleSettings: DataObject) { }
    static var id: String = "non-disableable"
    static let canBeDisabled: Bool = false
}
final class TealiumModulesTests: XCTestCase {
    let nonDisableableFactory = DefaultModuleFactory<NonDisableableModule>()
    let disableableFactory = DefaultModuleFactory<MockDispatcher1>()
    func test_shouldBeEnabled_on_NonDisableableModule_returns_true_for_settings_enabled() {
        XCTAssertTrue(nonDisableableFactory.shouldBeEnabled(by: ["enabled": true]))
    }

    func test_shouldBeEnabled_on_NonDisableableModule_returns_true_for_settings_disabled() {
        XCTAssertTrue(nonDisableableFactory.shouldBeEnabled(by: ["enabled": false]))
    }

    func test_shouldBeEnabled_on_NonDisableableModule_returns_true_for_settings_without_enabled_key() {
        XCTAssertTrue(nonDisableableFactory.shouldBeEnabled(by: [:]))
    }

    func test_shouldBeEnabled_on_DisableableModule_returns_true_for_settings_enabled() {
        XCTAssertTrue(disableableFactory.shouldBeEnabled(by: ["enabled": true]))
    }

    func test_shouldBeEnabled_on_DisableableModule_returns_false_for_settings_disabled() {
        XCTAssertFalse(disableableFactory.shouldBeEnabled(by: ["enabled": false]))
    }

    func test_shouldBeEnabled_on_DisableableModule_returns_true_for_settings_without_enabled_key() {
        XCTAssertTrue(disableableFactory.shouldBeEnabled(by: [:]))
    }
}
