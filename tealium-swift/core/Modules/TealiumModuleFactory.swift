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
     * Creates a new `Module` if the received module settings are correct for it's initialization.
     *
     * - Parameters:
     *  - context: The `TealiumContext` shared by all modules.
     *  - moduleSettings: The settings for this specific module, used to initialize it
     *  and potentially disable it if some mandatory settings are missing or invalid.
     *
     * - Returns: the newly created `Module`, if the initialization succeded, or nil.
     */
    func create(context: TealiumContext, moduleSettings: [String: Any]) -> Module?

    /** 
     * Returns some optional settings for this module that override any other Local or Remote settings fields.
     *
     * Only the values at the specific keys returned in this Dictionary will be enforced and remain constant during the life of this `Module`.
     * Other values at other keys that are not present in this Dictionary can be set by Local or Remote settings
     * and be updated by future Remote settings refreshes during the life of this `Module`.
     *
     * - Returns: An optional Dictionary containing some of the settings used by the `Module` that will be enforced and remain constant during the life of this `Module`.
     */
    func getEnforcedSettings() -> [String: Any]?
}

public extension TealiumModuleFactory {
    /// The unique id for the `Module` that this factory creates
    var id: String { Module.id }
    func getEnforcedSettings() -> [String: Any]? {
        nil
    }

    /// Returns true if the provided settings allow for the factory's `Module` to be enabled.
    func shouldBeEnabled(by settings: [String: Any]) -> Bool {
        Module.shouldBeEnabled(by: settings)
    }
}
