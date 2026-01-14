//
//  Tealium+MomentsAPI.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 28/10/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if momentsapi
import TealiumPrismCore
#endif

public extension Modules {
    /**
     * Returns a factory for creating the `MomentsAPIModule`.
     *
     * - Parameters:
     *   - block: A block with a utility builder that can be used to enforce some of the `MomentsAPISettings` instead of relying on Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `MomentsAPIModule`, other settings will still be affected by Local and Remote settings and updates.
     */
    static func momentsAPI(forcingSettings block: EnforcingSettings<MomentsAPISettingsBuilder>? = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<MomentsAPIModule>(moduleType: Modules.Types.momentsAPI,
                                             enforcedSettings: block?(MomentsAPISettingsBuilder()).build())
    }
}

public extension Tealium {
    /**
     * Provides access to the Moments API module functionality.
     * 
     * - Returns: The Moments API module instance
     */
    func momentsAPI() -> MomentsAPI {
        MomentsAPIWrapper(moduleProxy: createModuleProxy())
    }
}

public extension Modules.Types {
    /// Module type identifier for Moments API module.
    static let momentsAPI = "MomentsAPI"
}
