//
//  Tealium+Lifecycle.swift
//  tealium-prism
//
//  Created by Den Guzov on 28/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumPrismCore
#endif

public extension Modules {
    /**
     * Returns a factory for creating the `LifecycleModule`.
     *
     * - Parameters:
     *   - block: A block with a utility builder that can be used to enforce some of the `LifecycleSettings` instead of relying on Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `LifecycleModule`, other settings will still be affected by Local and Remote settings and updates.
     */
    static func lifecycle(forcingSettings block: EnforcingSettings<LifecycleSettingsBuilder>? = { $0 }) -> some ModuleFactory {
        LifecycleModule.Factory(forcingSettings: block)
    }
}

public extension Tealium {
    /**
     * Creates and returns a `Lifecycle` object, that can be used to send custom lifecycle events.
     *
     * If you intend to use this multiple time, keep a reference to the returned object
     * to avoid creating a new one every time you call `Tealium.lifecycle()`.
     */
    func lifecycle() -> Lifecycle {
        LifecycleWrapper(moduleProxy: createModuleProxy())
    }
}

public extension Modules.Types {
    static let lifecycle = "Lifecycle"
}
