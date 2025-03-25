//
//  TealiumModuleFactory.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A factory that is used to create a specific `TealiumModule` with some standard parameters.
 */
public protocol TealiumModuleFactory {

    /// The specific `TealiumModule` that this factory can create.
    associatedtype Module: TealiumModule

    /**
     * Creates a new `Module` if the received module configuration is correct for it's initialization.
     *
     * - Parameters:
     *   - context: The `TealiumContext` shared by all modules.
     *   - moduleConfiguration: The `DataObject` configuration for this specific module, used to initialize it
     *  and potentially disable it if some mandatory settings are missing or invalid.
     *
     * - Returns: the newly created `Module`, if the initialization succeeded, or nil.
     */
    func create(context: TealiumContext, moduleConfiguration: DataObject) -> Module?

    /**
     * Returns some optional settings for this module that override any other Local or Remote settings fields.
     *
     * Only the values at the specific keys returned in this Dictionary will be enforced and remain constant during the life of this `Module`.
     * Other values at other keys that are not present in this Dictionary can be set by Local or Remote settings
     * and be updated by future Remote settings refreshes during the life of this `Module`.
     *
     * - Returns: An optional `DataObject` representing the `ModuleSettings`, containing some of the settings used by the `Module` that will be enforced and remain constant during the life of this `Module`.
     */
    func getEnforcedSettings() -> DataObject?
}

extension TealiumModuleFactory {
    /// The unique id for the `Module` that this factory creates
    public var id: String { Module.id }
    public func getEnforcedSettings() -> DataObject? {
        nil
    }

    /// Returns true if the provided settings allow for the factory's `Module` to be enabled.
    func shouldBeEnabled(by settings: ModuleSettings) -> Bool {
        !Module.canBeDisabled || settings.enabled != false
    }
}
