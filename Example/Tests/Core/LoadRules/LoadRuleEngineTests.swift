//
//  LoadRuleEngineTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 25/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class LoadRuleEngineTests: XCTestCase {
    @StateSubject(SDKSettings())
    var sdkSettings: ObservableState<SDKSettings>
    lazy var engine = LoadRuleEngine(sdkSettings: sdkSettings)

    let moduleWithRules = MockModule()
    let moduleWithoutRules = MockDispatcher()

    static func settingsForRule(_ rule: Rule<String>, moduleId: String = MockModule.id) -> SDKSettings {
        SDKSettings(core: CoreSettings(),
                    modules: [
                        moduleId: ModuleSettings(rules: rule)
                    ],
                    loadRules: [
                        "true": LoadRule(id: "true", conditions: .just(AlwaysTrue())),
                        "false": LoadRule(id: "false", conditions: .just(AlwaysFalse())),
                        "equals": LoadRule(id: "equals", conditions: .just(Condition.equals(ignoreCase: false,
                                                                                            variable: "variable",
                                                                                            target: "value")))
                    ])
    }

    func test_expand_replaces_id_strings_with_provided_conditions() {
        let condition = Condition.equals(ignoreCase: true, variable: "key", target: "value")
        let expandedRule = LoadRuleEngine.expand(rule: .just("ruleId"),
                                                 with: ["ruleId": .just(condition)])

        XCTAssertTrue(Rule<Condition>.just(condition)
            .equals(expandedRule))
    }

    func test_rulesAllow_allows_to_dispatch_for_module_when_loadRule_is_found_and_applies() {
        _sdkSettings.value = Self.settingsForRule(.just("true"))

        XCTAssertTrue(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                        forModule: moduleWithRules))
    }

    func test_rulesAllow_doesnt_allow_to_dispatch_for_module_when_loadRule_is_found_but_doesnt_apply() {
        _sdkSettings.value = Self.settingsForRule(.just("false"))

        XCTAssertFalse(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                         forModule: moduleWithRules))
    }

    func test_rulesAllow_allows_to_dispatch_for_module_when_module_has_no_rules() {
        _sdkSettings.value = Self.settingsForRule(.just("false"))

        XCTAssertTrue(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                        forModule: moduleWithoutRules))
    }

    func test_rulesAllow_doesnt_allow_to_dispatch_for_module_when_loadRule_is_not_found() {
        _sdkSettings.value = Self.settingsForRule(.just("missing"))

        XCTAssertFalse(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                         forModule: moduleWithRules))
    }

    func test_rulesAllow_allows_to_dispatch_for_module_when_module_has_no_rules_and_loadRule_is_not_found() {
        _sdkSettings.value = Self.settingsForRule(.just("missing"))

        XCTAssertTrue(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                        forModule: moduleWithoutRules))
    }

    func test_filterDispatches_removes_not_allowed_dispatches_for_module() {
        _sdkSettings.value = Self.settingsForRule(.just("equals"))
        let dispatches = [
            Dispatch(name: "Allowed", data: ["variable": "value"]),
            Dispatch(name: "Not Allowed", data: ["variable": "notValue"])
        ]
        let filtered = engine.filterDispatches(dispatches, forModule: moduleWithRules)
        XCTAssertTrue(filtered.contains(where: { $0.name == "Allowed" }))
        XCTAssertFalse(filtered.contains(where: { $0.name == "Not Allowed" }))
    }

    func test_filterDispatches_doesnt_remove_any_dispatch_for_module_without_rules() {
        _sdkSettings.value = Self.settingsForRule(.just("equals"))
        let dispatches = [
            Dispatch(name: "Allowed", data: ["variable": "value"]),
            Dispatch(name: "Not Allowed", data: ["variable": "notValue"])
        ]
        let filtered = engine.filterDispatches(dispatches, forModule: moduleWithoutRules)
        XCTAssertTrue(filtered.contains(where: { $0.name == "Allowed" }))
        XCTAssertTrue(filtered.contains(where: { $0.name == "Not Allowed" }))
    }

    func test_filterDispatches_removes_all_dispatches_when_rule_is_not_found() {
        _sdkSettings.value = Self.settingsForRule(.just("missing"))
        let dispatches = [
            Dispatch(name: "Allowed", data: ["variable": "value"]),
            Dispatch(name: "Not Allowed", data: ["variable": "notValue"])
        ]
        let filtered = engine.filterDispatches(dispatches, forModule: moduleWithRules)
        XCTAssertFalse(filtered.contains(where: { $0.name == "Allowed" }))
        XCTAssertFalse(filtered.contains(where: { $0.name == "Not Allowed" }))
    }

    func test_ruleMap_is_updated_on_settings_update() {
        let condition = Condition.equals(ignoreCase: false, variable: "variable", target: "value")
        _sdkSettings.value = Self.settingsForRule(.just("equals"))
        guard let rule = engine.ruleMap[MockModule.id] else {
            XCTFail("Rule not found for \(MockModule.id) in ruleMap \(engine.ruleMap)")
            return
        }
        XCTAssertTrue(Rule<Condition>.just(condition).equals(rule))
        _sdkSettings.value = Self.settingsForRule(.just("equals"), moduleId: "NewModuleId")
        guard let newRule = engine.ruleMap["NewModuleId"] else {
            XCTFail("Rule not found for NewModuleId in ruleMap \(engine.ruleMap)")
            return
        }
        XCTAssertTrue(Rule<Condition>.just(condition).equals(newRule))
    }
}
