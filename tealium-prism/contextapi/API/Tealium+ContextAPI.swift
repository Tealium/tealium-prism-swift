//
//  Tealium+ContextAPI.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 28/10/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if contextapi
import TealiumPrismCore
#endif

public extension Modules {
    /**
     * Returns a factory for creating the `ContextAPIModule`.
     *
     * - Parameters:
     *   - block: A block with a utility builder that can be used to enforce some of the `ContextAPISettings` instead of relying on Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `ContextAPIModule`, other settings will still be affected by Local and Remote settings and updates.
     */
    static func contextAPI(forcingSettings block: EnforcingSettings<ContextAPISettingsBuilder>? = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<ContextAPIModule>(moduleType: Modules.Types.contextAPI,
                                             enforcedSettings: block?(ContextAPISettingsBuilder()).build())
    }
}

public extension Tealium {
    /**
     * Provides access to the Context API module functionality.
     * 
     * - Returns: The Context API module instance
     */
    func contextAPI() -> ContextAPI {
        ContextAPIWrapper(moduleProxy: createModuleProxy())
    }
}

public extension Modules.Types {
    /// Module type identifier for Context API module.
    static let contextAPI = "ContextAPI"
}
