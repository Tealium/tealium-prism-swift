//
//  LoadRuleEngine.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * The `LoadRuleEngine` is responsible for receiving the `SDKSettings` object, and transforming the
 * set of common `LoadRules` into composite `LoadRules` for specific `TealiumModule` implementations.
 *
 * That is, the `SDKSettings` has common, re-usable `LoadRule`s at `SDKSettings.loadRules`, and `TealiumModule`s
 * are able to reference them in their own `ModuleSettings.rules` property, as a `Rule<String>`.
 *
 * The `LoadRuleEngine` therefore builds `Matchable` implementations upon each update to the `SDKSettings`
 * the can be used to decide whether or not a particular `TealiumModule` can execute their task.
 */
class LoadRuleEngine {
    /// ModuleId : Expanded-LoadRules
    private(set) var moduleIdToRuleMap: [String: Rule<Matchable>] = [:]
    private let disposer = AutomaticDisposer()
    /// RuleID : LoadRule.Condition
    let ruleIdToRuleMap: ObservableState<[String: Rule<Matchable>]>

    init(sdkSettings: ObservableState<SDKSettings>) {
        ruleIdToRuleMap = sdkSettings.mapState { $0.loadRules.mapValues { $0.conditions } }
        sdkSettings.subscribe { [weak self] settings in
            guard let self else { return }
            self.moduleIdToRuleMap = settings.modules.compactMapValues { module in
                guard let rule = module.rules else { return nil }
                return Self.expand(rule: rule, with: self.ruleIdToRuleMap.value)
            }
        }.addTo(disposer)
    }

    /**
     * Evaluates the load rules for the given `module` against the provided `dispatch` and returns `true` if the
     * load rules allow the `dispatch` for the `module`. Otherwise it will return `false`.
     */
    func rulesAllow(dispatch: Dispatch, forModule module: TealiumModule) -> Bool {
        guard let rule = moduleIdToRuleMap[module.id] else {
            return true // no rule set, safe to execute
        }
        return rule.matches(payload: dispatch.payload)
    }

    /**
     * Evaluates the load rules for the given `module` and `dispatches`. The result is a `DispatchSplit`
     * which is a partition of the `dispatches` into two lists of either "passed" (`successful`) or "failed" (`unsuccessful`).
     */
    func evaluateLoadRules(on dispatches: [Dispatch], forModule module: TealiumModule) -> DispatchSplit {
        guard let rule = moduleIdToRuleMap[module.id] else {
            return (dispatches, [])
        }
        return dispatches.partitioned { rule.matches(payload: $0.payload) }
    }

    static func expand(rule: Rule<String>, with loadRules: [String: Rule<Matchable>]) -> Rule<Matchable> {
        rule.asMatchable { id in
            if id.lowercased() == "all" {
                return .just(AlwaysTrue())
            } else if let rule = loadRules[id] {
                return rule
            } else {
                // In case of no load rule found we default to the rule not matching any payload
                return .just(AlwaysFalse())
            }
        }
    }
}
