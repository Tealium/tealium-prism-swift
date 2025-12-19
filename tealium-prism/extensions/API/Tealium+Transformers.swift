//
//  Tealium+Transformers.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if extensions
import TealiumPrismCore
#endif

public extension Modules.Types {
    static let setDataValuesTransformer = "SetDataValues"
    static let persistDataValueTransformer = "PersistDataValue"
    static let lowerCaseTransformer = "LowerCase"
}

public extension Modules {
    static func setDataValuesTransformer(forcingSettings block: EnforcingSettings<ModuleSettingsBuilder> = { $0 }) -> some ModuleFactory {
        DefaultModuleFactory<SetDataValuesTransformer>(moduleType: Modules.Types.setDataValuesTransformer,
                                                       enforcedSettings: block(DataLayerSettingsBuilder()).build())
    }

    static func persistDataValueTransformer(forcingSettings block: EnforcingSettings<ModuleSettingsBuilder> = { $0 }) -> some ModuleFactory {
        DefaultModuleFactory<PersistDataValueTransformer>(moduleType: Modules.Types.persistDataValueTransformer,
                                                          enforcedSettings: block(DataLayerSettingsBuilder()).build())
    }

    static func lowerCaseTransformer(forcingSettings block: EnforcingSettings<ModuleSettingsBuilder> = { $0 }) -> some ModuleFactory {
        DefaultModuleFactory<LowerCaseTransformer>(moduleType: Modules.Types.lowerCaseTransformer,
                                                   enforcedSettings: block(DataLayerSettingsBuilder()).build())
    }
}
