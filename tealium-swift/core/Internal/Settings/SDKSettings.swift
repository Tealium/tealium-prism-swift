//
//  SDKSettings.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A container of settings for each module.
struct SDKSettings {
    enum Keys {
        static let core = "core"
        static let modules = "modules"
        static let loadRules = "load_rules"
        static let transformations = "transformations"
    }
    let core: CoreSettings
    let modules: [String: ModuleSettings]
    let loadRules: [String: LoadRule]
    let transformations: [String: TransformationSettings]

    init(_ settings: DataObject) {
        self.init(core: settings.getConvertible(key: Keys.core,
                                                converter: CoreSettings.converter) ?? CoreSettings(),
                  modules: settings.getDataDictionary(key: Keys.modules)?
            .compactMapValues { $0.getConvertible(converter: ModuleSettings.converter) } ?? [:],
                  loadRules: settings.getDataDictionary(key: Keys.loadRules)?
            .compactMapValues {
                $0.getConvertible(converter: LoadRule.converter)
            } ?? [:],
                  transformations: settings.getDataDictionary(key: Keys.transformations)?
            .compactMapValues {
                $0.getConvertible(converter: TransformationSettings.converter)
            } ?? [:])
    }

    init(modules: [String: DataObject] = [:]) {
        self.init([Keys.modules: modules])
    }

    init(core: CoreSettings,
         modules: [String: ModuleSettings] = [:],
         loadRules: [String: LoadRule] = [:],
         transformations: [String: TransformationSettings] = [:]) {
        self.core = core
        self.modules = modules
        self.loadRules = loadRules
        self.transformations = transformations
    }
}
