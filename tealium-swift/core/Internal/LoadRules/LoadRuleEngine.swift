//
//  LoadRuleEngine.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

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

    func rulesAllow(dispatch: Dispatch, forModule module: TealiumModule) -> Bool {
        !filterDispatches([dispatch], forModule: module).isEmpty
    }

    func filterDispatches(_ dispatches: [Dispatch], forModule module: TealiumModule) -> [Dispatch] {
        guard let dispatcherRule = moduleIdToRuleMap[module.id] else {
            return dispatches
        }
        return dispatches.filter { dispatch in
            dispatcherRule.matches(payload: dispatch.payload)
        }
    }

    func rule(_ ruleId: String, allows payload: DataObject) -> Bool {
        Self.expand(rule: .just(ruleId), with: self.ruleIdToRuleMap.value)
            .matches(payload: payload)
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
