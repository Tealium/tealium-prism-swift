//
//  Tealium+Lifecycle.swift
//  tealium-swift
//
//  Created by Den Guzov on 28/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

public extension TealiumModules {
    /**
     * Returns a factory for creating the `LifecycleModule`.
     *
     * - Parameters:
     *   - block: A block with a utility builder that can be used to enforce some of the `LifecycleSettings` instead of relying on Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `LifecycleModule`, other settings will still be affected by Local and Remote settings and updates.
     */
    static func lifecycle(forcingSettings block: ((_ enforcedSettings: LifecycleSettingsBuilder) -> LifecycleSettingsBuilder)? = nil) -> any TealiumModuleFactory {
        LifecycleModule.Factory(forcingSettings: block)
    }
}

public extension Tealium {
    var lifecycle: Lifecycle {
        LifecycleWrapper(moduleProxy: createModuleProxy())
    }
}
