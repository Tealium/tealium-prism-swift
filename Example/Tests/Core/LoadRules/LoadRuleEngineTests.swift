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

    override func setUp() {
        _sdkSettings.add(loadRules: [
            "true": LoadRule(id: "true", conditions: .just(AlwaysTrue())),
            "false": LoadRule(id: "false", conditions: .just(AlwaysFalse())),
            "equals": LoadRule(id: "equals", conditions: .just(Condition.equals(ignoreCase: false,
                                                                                variable: "variable",
                                                                                target: "value")))
        ])
    }

    func addRule(_ rule: Rule<String>, moduleId: String = MockModule.id) {
        _sdkSettings.add(modules: [
            moduleId: ModuleSettings(rules: rule)
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
        addRule(.just("true"))

        XCTAssertTrue(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                        forModule: moduleWithRules))
    }

    func test_rulesAllow_doesnt_allow_to_dispatch_for_module_when_loadRule_is_found_but_doesnt_apply() {
        addRule(.just("false"))

        XCTAssertFalse(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                         forModule: moduleWithRules))
    }

    func test_rulesAllow_allows_to_dispatch_for_module_when_module_has_no_rules() {
        addRule(.just("false"))

        XCTAssertTrue(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                        forModule: moduleWithoutRules))
    }

    func test_rulesAllow_doesnt_allow_to_dispatch_for_module_when_loadRule_is_not_found() {
        addRule(.just("missing"))

        XCTAssertFalse(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                         forModule: moduleWithRules))
    }

    func test_rulesAllow_allows_to_dispatch_for_module_when_module_has_no_rules_and_loadRule_is_not_found() {
        addRule(.just("missing"))

        XCTAssertTrue(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                        forModule: moduleWithoutRules))
    }

    func test_filterDispatches_removes_not_allowed_dispatches_for_module() {
        addRule(.just("equals"))
        let dispatches = [
            Dispatch(name: "Allowed", data: ["variable": "value"]),
            Dispatch(name: "Not Allowed", data: ["variable": "notValue"])
        ]
        let (passed, failed) = engine.evaluateLoadRules(on: dispatches, forModule: moduleWithRules)
        XCTAssertTrue(passed.contains(where: { $0.name == "Allowed" }))
        XCTAssertFalse(passed.contains(where: { $0.name == "Not Allowed" }))
        XCTAssertTrue(failed.contains(where: { $0.name == "Not Allowed" }))
        XCTAssertFalse(failed.contains(where: { $0.name == "Allowed" }))
    }

    func test_filterDispatches_doesnt_remove_any_dispatch_for_module_without_rules() {
        addRule(.just("equals"))
        let dispatches = [
            Dispatch(name: "Allowed", data: ["variable": "value"]),
            Dispatch(name: "Not Allowed", data: ["variable": "notValue"])
        ]
        let (passed, failed) = engine.evaluateLoadRules(on: dispatches, forModule: moduleWithoutRules)
        XCTAssertTrue(passed.contains(where: { $0.name == "Allowed" }))
        XCTAssertTrue(passed.contains(where: { $0.name == "Not Allowed" }))
        XCTAssertTrue(failed.isEmpty)
    }

    func test_filterDispatches_removes_all_dispatches_when_rule_is_not_found() {
        addRule(.just("missing"))
        let dispatches = [
            Dispatch(name: "Allowed", data: ["variable": "value"]),
            Dispatch(name: "Not Allowed", data: ["variable": "notValue"])
        ]
        let (passed, failed) = engine.evaluateLoadRules(on: dispatches, forModule: moduleWithRules)
        XCTAssertTrue(passed.isEmpty)
        XCTAssertTrue(failed.contains(where: { $0.name == "Allowed" }))
        XCTAssertTrue(failed.contains(where: { $0.name == "Not Allowed" }))
    }

    func test_ruleMap_is_updated_on_settings_update() {
        let condition = Condition.equals(ignoreCase: false, variable: "variable", target: "value")
        addRule(.just("equals"))
        guard let rule = engine.moduleIdToRuleMap[MockModule.id] else {
            XCTFail("Rule not found for \(MockModule.id) in ruleMap \(engine.moduleIdToRuleMap)")
            return
        }
        XCTAssertTrue(Rule<Condition>.just(condition).equals(rule))
        addRule(.just("equals"), moduleId: "NewModuleId")
        guard let newRule = engine.moduleIdToRuleMap["NewModuleId"] else {
            XCTFail("Rule not found for NewModuleId in ruleMap \(engine.moduleIdToRuleMap)")
            return
        }
        XCTAssertTrue(Rule<Condition>.just(condition).equals(newRule))
    }
}
