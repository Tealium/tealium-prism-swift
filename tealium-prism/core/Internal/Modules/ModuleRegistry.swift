//
//  ModuleRegistry.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 14/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Internal singleton available to hold all default modules and add any additional ones that may be registered at init time.
 */
class ModuleRegistry {

    /// The modules created within the Core library.
    private var _defaultModules: [any ModuleFactory] = [
        Modules.appData(forcingSettings: nil),
        Modules.collect(forcingSettings: nil),
        Modules.connectivityData(forcingSettings: nil),
        Modules.dataLayer(),
        Modules.deepLink(forcingSettings: nil),
        Modules.deviceData(forcingSettings: nil),
        Modules.tealiumData(),
        Modules.timeData(forcingSettings: nil),
        Modules.trace(forcingSettings: nil)
    ]

    /// The optional modules that need to be installed alongside the Core library.
    private(set) var additionalModules: [any ModuleFactory] = []

    /// A list of default modules that will be added to the provided modules.
    var defaultModules: [any ModuleFactory] {
        _defaultModules + additionalModules
    }

    static let shared = ModuleRegistry()
    private init() { }

    func addDefaultModule<SpecificFactory: ModuleFactory>(_ module: SpecificFactory) {
        additionalModules.append(module)
    }
}
