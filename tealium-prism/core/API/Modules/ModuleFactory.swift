//
//  ModuleFactory.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A factory that is used to create a specific `Module` with some standard parameters.
 */
public protocol ModuleFactory {

    /// The specific `Module` that this factory can create.
    associatedtype SpecificModule: Module

    /// Returns true if the module can be instantiated multiple times.
    var allowsMultipleInstances: Bool { get }

    /// The type of `Module` that this factory creates
    var moduleType: String { get }

    /**
     * Creates a new `Module` if the received module configuration is correct for it's initialization.
     *
     * - Parameters:
     *   - moduleId: The ID for this specific instance of the module.
     *   - context: The `TealiumContext` shared by all modules.
     *   - moduleConfiguration: The `DataObject` configuration for this specific module, used to initialize it
     *  and potentially disable it if some mandatory settings are missing or invalid.
     *
     * - Returns: the newly created `Module`, if the initialization succeeded, or nil.
     */
    func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> SpecificModule?

    /**
     * Returns some optional settings for this module that override any other Local or Remote settings fields.
     *
     * Only the values at the specific keys returned in this Dictionary will be enforced and remain constant during the life of this `Module`.
     * Other values at other keys that are not present in this Dictionary can be set by Local or Remote settings
     * and be updated by future Remote settings refreshes during the life of this `Module`.
     *
     * - Returns: An array of `DataObject` representing the `ModuleSettings`, containing some of the settings used by the `Module`
     * that will be enforced and remain constant during the life of this `Module`. Each `DataObject` in the Array will be used for the settings
     * of one instance of the `Module`, if this module allows to be initialized multiple times. Otherwise only the first one will be used.
     * In case of multiple settings, be sure to provide a unique module ID by calling `MultipleInstancesModuleSettingsBuilder.setModuleId(_:)`.
     * If no module ID is provided, moduleType will be used instead. If two or more module IDs are the same, only the first settings object
     * will be used by the caller; subsequent settings will be discarded.
     * If this method returns an empty array, the `ModuleFactory` will not instantiate any `Module` by default.
     * In this case modules will be instantiated only if they are configured in the local or remote settings.
     */
    func getEnforcedSettings() -> [DataObject]
}

extension ModuleFactory {
    public func getEnforcedSettings() -> [DataObject] {
        []
    }

    /// Returns true if the provided settings allow for the factory's `Module` to be enabled.
    func shouldBeEnabled(by settings: ModuleSettings) -> Bool {
        !SpecificModule.canBeDisabled || settings.enabled != false
    }
}
