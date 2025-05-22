//
//  LoadRuleEngine.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

class LoadRuleEngine {
    /// ModuleId : Expanded-LoadRules
    private(set) var ruleMap: [String: Rule<Matchable>] = [:]
    private let disposer = AutomaticDisposer()

    init(sdkSettings: ObservableState<SDKSettings>) {
        sdkSettings.subscribe { [weak self] settings in
            guard let self else { return }
            self.ruleMap = settings.modules.compactMapValues { module in
                guard let rule = module.rules else { return nil }
                return Self.expand(rule: rule, with: settings.loadRules.mapValues { $0.conditions })
            }
        }.addTo(disposer)
    }

    func rulesAllow(dispatch: Dispatch, forModule module: TealiumModule) -> Bool {
        !filterDispatches([dispatch], forModule: module).isEmpty
    }

    func filterDispatches(_ dispatches: [Dispatch], forModule module: TealiumModule) -> [Dispatch] {
        guard let dispatcherRule = ruleMap[module.id] else {
            return dispatches
        }
        return dispatches.filter { dispatch in
            dispatcherRule.matches(payload: dispatch.payload)
        }
    }

    static func expand(rule: Rule<String>, with loadRules: [String: Rule<Matchable>]) -> Rule<Matchable> {
        rule.asMatchable { id in
            if let rule = loadRules[id] {
                return rule
            } else {
                // In case of no load rule found we default to the rule not matching any payload
                return .just(AlwaysFalse())
            }
        }
    }
}
