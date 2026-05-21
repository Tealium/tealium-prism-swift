//
//  Transformer+BasicModule.swift
//  tealium-prism
//
//  Created by Denis Guzov on 21/05/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

public extension Transformer where Self: BasicModule {
    /// Returns a `BasicModuleFactory` for this transformer, used by automatic-loader classes
    /// to register the transformer as a default module. Not intended for direct use.
    static var factory: BasicModuleFactory<Self> {
        BasicModuleFactory<Self>(moduleType: Self.moduleType, enforcedSettings: ModuleSettingsBuilder().build())
    }
}
