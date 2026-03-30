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
    /// The module type identifier for the SetDataValues transformer.
    static let setDataValuesTransformer = "SetDataValues"
    /// The module type identifier for the PersistDataValue transformer.
    static let persistDataValueTransformer = "PersistDataValue"
    /// The module type identifier for the LowerCase transformer.
    static let lowerCaseTransformer = "LowerCase"
}

public extension Modules {
    /// Creates a factory for the SetDataValues transformer module.
    ///
    /// The SetDataValues transformer copies or sets values in the dispatch payload
    /// based on configured operations. Use `SetDataValuesSettingsBuilder` to configure
    /// the transformation settings.
    ///
    /// - Parameter block: An optional closure to enforce specific module settings.
    /// - Returns: A `ModuleFactory` that creates `SetDataValuesTransformer` instances.
    static func setDataValuesTransformer(forcingSettings block: EnforcingSettings<ModuleSettingsBuilder> = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<SetDataValuesTransformer>(moduleType: Modules.Types.setDataValuesTransformer,
                                                     enforcedSettings: block(ModuleSettingsBuilder()).build())
    }

    /// Creates a factory for the PersistDataValue transformer module.
    ///
    /// The PersistDataValue transformer persists a value from the dispatch payload (or a constant) to the data layer
    /// with a configurable expiry and update policy. When the value is successfully written to the data layer,
    /// the effective persisted value is also injected into the current dispatch payload. The original dispatch payload
    /// may be returned unchanged (for example, when an existing value is kept or when persistence fails).
    /// Use `PersistDataValueSettingsBuilder` to configure the transformation settings.
    ///
    /// If expiry or update policy are not specified, defaults to `.session` expiry and `.allowUpdate` policy.
    ///
    /// - Parameter block: An optional closure to enforce specific module settings.
    /// - Returns: A `ModuleFactory` that creates `PersistDataValueTransformer` instances.
    static func persistDataValueTransformer(forcingSettings block: EnforcingSettings<ModuleSettingsBuilder> = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<PersistDataValueTransformer>(moduleType: Modules.Types.persistDataValueTransformer,
                                                        enforcedSettings: block(DataLayerSettingsBuilder()).build())
    }

    /// Creates a factory for the LowerCase transformer module.
    ///
    /// The LowerCase transformer converts string values in the dispatch payload to lowercase.
    /// By default it applies to all strings in the payload. Use `LowerCaseSettingsBuilder` to
    /// configure the transformation settings.
    ///
    /// - Parameter block: An optional closure to enforce specific module settings.
    /// - Returns: A `ModuleFactory` that creates `LowerCaseTransformer` instances.
    static func lowerCaseTransformer(forcingSettings block: EnforcingSettings<ModuleSettingsBuilder> = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<LowerCaseTransformer>(moduleType: Modules.Types.lowerCaseTransformer,
                                                 enforcedSettings: block(ModuleSettingsBuilder()).build())
    }
}
