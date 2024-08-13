//
//  TealiumModulesTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest
class NonDisableableModule: TealiumModule {
    static var id: String = "non-disableable"
    static let canBeDisabled: Bool = false
}
final class TealiumModulesTests: XCTestCase {
    func test_shouldBeEnabled_on_NonDisableableModule_returns_true_for_settings_enabled() {
        XCTAssertTrue(NonDisableableModule.shouldBeEnabled(by: ["enabled": true]))
    }

    func test_shouldBeEnabled_on_NonDisableableModule_returns_true_for_settings_disabled() {
        XCTAssertTrue(NonDisableableModule.shouldBeEnabled(by: ["enabled": false]))
    }

    func test_shouldBeEnabled_on_NonDisableableModule_returns_true_for_settings_without_enabled_key() {
        XCTAssertTrue(NonDisableableModule.shouldBeEnabled(by: [:]))
    }

    func test_shouldBeEnabled_on_DisableableModule_returns_true_for_settings_enabled() {
        XCTAssertTrue(MockDispatcher1.shouldBeEnabled(by: ["enabled": true]))
    }

    func test_shouldBeEnabled_on_DisableableModule_returns_false_for_settings_disabled() {
        XCTAssertFalse(MockDispatcher1.shouldBeEnabled(by: ["enabled": false]))
    }

    func test_shouldBeEnabled_on_DisableableModule_returns_true_for_settings_without_enabled_key() {
        XCTAssertTrue(MockDispatcher1.shouldBeEnabled(by: [:]))
    }
}
