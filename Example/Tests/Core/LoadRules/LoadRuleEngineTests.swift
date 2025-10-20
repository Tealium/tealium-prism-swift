//
//  LoadRuleEngineTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 25/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LoadRuleEngineTests: XCTestCase {
    lazy var logger: MockLogger? = nil
    @StateSubject(SDKSettings())
    var sdkSettings
    lazy var engine = LoadRuleEngine(sdkSettings: sdkSettings, logger: logger)

    let moduleWithRules = MockModule()
    let moduleWithoutRules = MockDispatcher()

    override func setUp() {
        _sdkSettings.add(loadRules: [
            "true": LoadRule(id: "true", conditions: .just(AlwaysTrue())),
            "false": LoadRule(id: "false", conditions: .just(AlwaysFalse())),
            "equals": LoadRule(id: "equals", conditions: .just(Condition.equals(ignoreCase: false,
                                                                                variable: "variable",
                                                                                target: "value"))),
            "noDataItem": LoadRule(id: "equals", conditions: .just(Condition.equals(ignoreCase: false,
                                                                                    variable: "missing",
                                                                                    target: "value")))
        ])
    }

    func addRule(_ rule: Rule<String>, moduleType: String = MockModule.moduleType) {
        _sdkSettings.add(modules: [
            moduleType: ModuleSettings(moduleType: moduleType, rules: rule)
        ])
    }

    func test_expand_replaces_id_strings_with_provided_conditions() {
        let condition = Condition.equals(ignoreCase: true, variable: "key", target: "value")
        let expandedRule = LoadRuleEngine.expand(rule: .just("ruleId"),
                                                 with: ["ruleId": .just(condition)],
                                                 moduleId: "")

        XCTAssertTrue(Rule<Condition>.just(condition)
            .equals(expandedRule))
    }

    func test_expand_replaces_id_string_all_with_always_true_matchable() {
        let expandedRule = LoadRuleEngine.expand(rule: .just("all"),
                                                 with: [:],
                                                 moduleId: "")

        XCTAssertTrue(try expandedRule.matches(payload: [:]))
    }

    func test_expand_replaces_id_strings_with_throwing_matchable_when_not_found() {
        let expandedRule = LoadRuleEngine.expand(rule: .just("missing"),
                                                 with: [:],
                                                 moduleId: "test")
        XCTAssertThrowsError(try expandedRule.matches(payload: [:])) { error in
            guard let loadRuleError = error as? RuleNotFoundError else {
                XCTFail("Should be rule not found error, found: \(error)")
                return
            }
            XCTAssertEqual(loadRuleError.ruleId, "missing")
            XCTAssertEqual(loadRuleError.moduleId, "test")
        }
    }

    func test_rulesAllow_allows_to_dispatch_for_module_when_loadRule_is_found_and_applies() {
        addRule("true")

        XCTAssertTrue(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                        forModule: moduleWithRules))
    }

    func test_rulesAllow_doesnt_allow_to_dispatch_for_module_when_loadRule_is_found_but_doesnt_apply() {
        addRule("false")

        XCTAssertFalse(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                         forModule: moduleWithRules))
    }

    func test_rulesAllow_allows_to_dispatch_for_module_when_module_has_no_rules() {
        addRule("false")

        XCTAssertTrue(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                        forModule: moduleWithoutRules))
    }

    func test_rulesAllow_doesnt_allow_to_dispatch_for_module_and_logs_error_when_loadRule_is_not_found() {
        addRule("missing")
        let errorLogged = expectation(description: "InvalidMatchError is logged")
        logger = MockLogger()
        logger?.handler.onLogged.subscribeOnce({ logEvent in
            XCTAssertEqual(logEvent.category, LogCategory.loadRules)
            XCTAssertEqual(logEvent.level, .warn)
            errorLogged.fulfill()
        })

        XCTAssertFalse(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                         forModule: moduleWithRules))
        waitForDefaultTimeout()
    }

    func test_rulesAllow_doesnt_allow_to_dispatch_for_module_and_logs_error_when_condition_throws() {
        addRule("noDataItem")
        let errorLogged = expectation(description: "InvalidMatchError is logged")
        logger = MockLogger()
        logger?.handler.onLogged.subscribeOnce({ logEvent in
            XCTAssertEqual(logEvent.category, LogCategory.loadRules)
            XCTAssertEqual(logEvent.level, .warn)
            errorLogged.fulfill()
        })

        XCTAssertFalse(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                         forModule: moduleWithRules))
        waitForDefaultTimeout()
    }

    func test_rulesAllow_allows_to_dispatch_for_module_when_module_has_no_rules_and_loadRule_is_not_found() {
        addRule("missing")

        XCTAssertTrue(engine.rulesAllow(dispatch: Dispatch(name: "event"),
                                        forModule: moduleWithoutRules))
    }

    func test_filterDispatches_removes_not_allowed_dispatches_for_module() {
        addRule("equals")
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
        addRule("equals")
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
        addRule("missing")
        let dispatches = [
            Dispatch(name: "Allowed", data: ["variable": "value"]),
            Dispatch(name: "Not Allowed", data: ["variable": "notValue"])
        ]
        let (passed, failed) = engine.evaluateLoadRules(on: dispatches, forModule: moduleWithRules)
        XCTAssertTrue(passed.isEmpty)
        XCTAssertTrue(failed.contains(where: { $0.name == "Allowed" }))
        XCTAssertTrue(failed.contains(where: { $0.name == "Not Allowed" }))
    }

    func test_filterDispatches_removes_dispatch_and_logs_error_when_condition_throws() {
        addRule("noDataItem")
        let errorLogged = expectation(description: "InvalidMatchError is logged")
        logger = MockLogger()
        logger?.handler.onLogged.subscribeOnce({ logEvent in
            XCTAssertEqual(logEvent.category, LogCategory.loadRules)
            XCTAssertEqual(logEvent.level, .warn)
            errorLogged.fulfill()
        })
        let dispatches = [Dispatch(name: "Removed", data: ["variable": "value"])]
        let (passed, failed) = engine.evaluateLoadRules(on: dispatches, forModule: moduleWithRules)
        XCTAssertTrue(passed.isEmpty)
        XCTAssertTrue(failed.contains(where: { $0.name == "Removed" }))
        waitForDefaultTimeout()
    }

    func test_ruleMap_is_updated_on_settings_update() {
        let condition = Condition.equals(ignoreCase: false, variable: "variable", target: "value")
        addRule("equals")
        guard let rule = engine.moduleIdToRuleMap[MockModule.moduleType] else {
            XCTFail("Rule not found for \(MockModule.moduleType) in ruleMap \(engine.moduleIdToRuleMap)")
            return
        }
        XCTAssertTrue(Rule<Condition>.just(condition).equals(rule))
        addRule("equals", moduleType: "NewModuleType")
        guard let newRule = engine.moduleIdToRuleMap["NewModuleType"] else {
            XCTFail("Rule not found for NewModuleId in ruleMap \(engine.moduleIdToRuleMap)")
            return
        }
        XCTAssertTrue(Rule<Condition>.just(condition).equals(newRule))
    }
}
