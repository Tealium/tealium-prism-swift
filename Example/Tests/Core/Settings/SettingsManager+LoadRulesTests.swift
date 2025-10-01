//
//  SettingsManager+LoadRulesTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 27/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SettingsManagerLoadRulesTests: SettingsManagerTestCase {

    func test_loadRules_are_merged_on_init() throws {
        config.bundle = Bundle(for: type(of: self))
        let condition = Condition(path: nil, variable: "variable", operator: .equals(true), filter: "value")
        config.setLoadRule(.just(condition), forId: "programmaticRule")
        let manager = try getManager()
        let modulesSettings = manager.settings.value
        guard case let .just(item) = modulesSettings.loadRules["programmaticRule"]?.conditions else {
            XCTFail("Failed to extract programmatic JUST rule")
            return
        }
        XCTAssertEqual(item as? Condition, condition)
        guard case let .and(children) = modulesSettings.loadRules["localRule"]?.conditions else {
            XCTFail("Failed to extract local AND rule")
            return
        }
        guard case let .just(localItem) = children.first else {
            XCTFail("Failed to extract local JUST rule")
            return
        }
        XCTAssertEqual(localItem as? Condition, Condition(path: nil, variable: "variable", operator: .isDefined, filter: nil))
    }

    func test_loadRules_keys_are_overridden_on_init() throws {
        config.bundle = Bundle(for: type(of: self))
        let condition = Condition(path: nil, variable: "variable", operator: .equals(true), filter: "value")
        config.setLoadRule(.just(condition), forId: "localRule")
        let manager = try getManager()
        let modulesSettings = manager.settings.value
        guard case let .just(item) = modulesSettings.loadRules["localRule"]?.conditions else {
            XCTFail("Failed to extract programmatic JUST rule")
            return
        }
        XCTAssertEqual(item as? Condition, condition)
    }
}
