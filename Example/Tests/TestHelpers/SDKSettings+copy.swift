//
//  SDKSettings+copy.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism

extension SDKSettings {
    func copyWith(modules: [String: ModuleSettings] = [:],
                  loadRules: [String: LoadRule] = [:],
                  transformations: [String: TransformationSettings] = [:],
                  barriers: [String: BarrierSettings] = [:]) -> SDKSettings {
        SDKSettings(core: self.core,
                    modules: self.modules + modules,
                    loadRules: self.loadRules + loadRules,
                    transformations: self.transformations + transformations,
                    barriers: self.barriers + barriers)
    }
}

extension StateSubject<SDKSettings> {
    func add(modules: [String: ModuleSettings] = [:],
             loadRules: [String: LoadRule] = [:],
             transformations: [String: TransformationSettings] = [:],
             barriers: [String: BarrierSettings] = [:]) {
        value = value.copyWith(modules: modules,
                               loadRules: loadRules,
                               transformations: transformations,
                               barriers: barriers)
    }
}
