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
        let condition = Condition(variable: "variable", operator: .equals(true), filter: "value")
        config.setLoadRule(.just(condition), forId: "programmaticRule")
        let manager = try getManager()
        let modulesSettings = manager.settings.value
        XCTAssertEqual(modulesSettings.loadRules["programmaticRule"]?.conditions, .just(condition))
        XCTAssertEqual(modulesSettings.loadRules["localRule"]?.conditions,
                       .and([.just(Condition(variable: "variable", operator: .isDefined, filter: nil))]))
    }

    func test_loadRules_keys_are_overridden_on_init() throws {
        config.bundle = Bundle(for: type(of: self))
        let condition = Condition(variable: "variable", operator: .equals(true), filter: "value")
        config.setLoadRule(.just(condition), forId: "localRule")
        let manager = try getManager()
        let modulesSettings = manager.settings.value
        XCTAssertEqual(modulesSettings.loadRules["localRule"]?.conditions, .just(condition))
    }
}
