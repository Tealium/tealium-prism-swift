//
//  DisableableModuleSettingsBuilderTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DisableableModuleSettingsBuilderTests: XCTestCase {
    func test_build_returns_enabled_key_when_passed() {
        XCTAssertEqual(DisableableModuleSettingsBuilder().setEnabled(true).build(), ["enabled": true])
        XCTAssertEqual(DisableableModuleSettingsBuilder().setEnabled(false).build(), ["enabled": false])
    }

    func test_build_returns_empty_dictionary_when_enabled_not_passed() {
        XCTAssertEqual(DisableableModuleSettingsBuilder().build(), [:])
    }
}
