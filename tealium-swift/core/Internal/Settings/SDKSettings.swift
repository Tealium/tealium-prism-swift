//
//  SDKSettings.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A container of settings for each module.
struct SDKSettings: Equatable {
    enum Keys {
        static let core = "core"
        static let modules = "modules"
        static let loadRules = "load_rules"
    }
    let core: CoreSettings
    let modules: [String: ModuleSettings]

    init(_ settings: DataObject) {
        self.core = settings.getConvertible(key: Keys.core, converter: CoreSettings.converter) ?? CoreSettings()
        self.modules = settings.getDataDictionary(key: Keys.modules)?.compactMapValues { $0.getConvertible(converter: ModuleSettings.converter) } ?? [:]
    }

    init(modules: [String: DataObject] = [:]) {
        self.init([Keys.modules: modules])
    }

    init(core: CoreSettings, modules: [String: ModuleSettings] = [:]) {
        self.core = core
        self.modules = modules
    }
}
