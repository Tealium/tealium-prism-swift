//
//  SetDataValuesFactory.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if !os(watchOS)
import Foundation
#if jstransformer
import TealiumPrismCore
#endif

public extension Modules.Types {
    static let javaScriptTransformer = "JavaScriptTransformer"
}

public extension Modules {
    static func javaScriptTransformer(forcingSettings block: EnforcingSettings<ModuleSettingsBuilder> = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<JavaScriptTransformer>(moduleType: Modules.Types.javaScriptTransformer,
                                                  enforcedSettings: block(ModuleSettingsBuilder()).build())
    }
}
#endif
