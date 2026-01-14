//
//  BasicModuleFactory.swift
//  tealium-prism
//
//  Created by Den Guzov on 03/12/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A basic factory that can be reused to create modules that have no extra dependencies and can only be initialized once.
 *
 * `BasicModuleFactory` is a generic implementation of `ModuleFactory` that simplifies the creation of modules
 * conforming to the `BasicModule` protocol.
 *
 * For detailed guidance on creating custom modules, see [Creating Custom Modules](../../custommodules.html).
 *
 * ## Important Notes
 * - The generic `Module` type must conform to `BasicModule`
 * - Modules created by this factory cannot be instantiated multiple times (`allowsMultipleInstances` is always `false`)
 * - Use `ModuleSettingsBuilder` subclasses for type-safe configuration
 * - Module type constants should be defined in `Modules.Types` for consistency
 */
public class BasicModuleFactory<Module: BasicModule>: ModuleFactory {
    let enforcedSettings: [DataObject]
    /// The unique identifier for the type of module this factory creates.
    public let moduleType: String
    /// Always `false` for BasicModuleFactory - modules can only be instantiated once.
    public let allowsMultipleInstances: Bool = false
    /**
     * Creates a new BasicModuleFactory for the specified module type.
     *
     * - Parameters:
     *   - moduleType: A unique string identifier for the module type. This should match
     *                 the module type used in settings and configuration.
     *   - enforcedSettings: Optional settings that will be enforced for this module,
     *                      overriding any local or remote settings. If provided, the module
     *                      will be initialized even without additional configuration.
     *                      If `nil`, the module will only be initialized when local or
     *                      remote settings are available.
     */
    public init(moduleType: String, enforcedSettings: DataObject? = nil) {
        self.moduleType = moduleType
        self.enforcedSettings = [enforcedSettings].compactMap { $0 }
    }

    /**
     * Creates a new instance of the module with the provided configuration.
     *
     * This method delegates to the module's required initializer, passing the context
     * and configuration. The module can return `nil` if initialization fails due to
     * invalid or insufficient configuration.
     *
     * - Parameters:
     *   - moduleId: The unique identifier for this specific module instance (ignored for BasicModuleFactory - only one module instance allowed)
     *   - context: The shared TealiumContext containing dependencies and configuration.
     *   - moduleConfiguration: The configuration data for this module.
     *
     * - Returns: A new module instance if initialization succeeds, or `nil` if it fails.
     */
    public func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> Module? {
        Module(context: context, moduleConfiguration: moduleConfiguration)
    }

    /**
     * Returns the enforced settings for this module.
     *
     * These settings will override any corresponding values from local or remote settings
     * and remain constant throughout the module's lifecycle.
     *
     * - Returns: An array containing the enforced settings DataObject, or an empty array
     *           if no enforced settings were provided during initialization.
     */
    public func getEnforcedSettings() -> [DataObject] {
        enforcedSettings
    }
}
