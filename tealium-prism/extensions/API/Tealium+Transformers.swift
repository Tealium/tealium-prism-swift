//
//  SetDataValuesFactory.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if extensions
import TealiumPrismCore
#endif

public extension Modules.Types {
    static let setDataValuesTransformer = "SetDataValues"
}

public extension Modules {
    static func setDataValuesTransformer(forcingSettings block: EnforcingSettings<ModuleSettingsBuilder> = { $0 }) -> some ModuleFactory {
        DefaultModuleFactory<SetDataValuesTransformer>(moduleType: Modules.Types.setDataValuesTransformer,
                                                       enforcedSettings: block(DataLayerSettingsBuilder()).build())
    }
}
