//
//  Modules.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 08/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Modules {
    /// The Types for the modules
    enum Types {
        /// Module type identifier for AppData module.
        static public let appData = "AppData"
        /// Module type identifier for Collect module.
        static public let collect = "Collect"
        /// Module type identifier for DataLayer module.
        static public let dataLayer = "DataLayer"
        /// Module type identifier for DeviceData module.
        static public let deviceData = "DeviceData"
        /// Module type identifier for Trace module.
        static public let trace = "Trace"
        /// Module type identifier for DeepLink module.
        static public let deepLink = "DeepLink"
        /// Module type identifier for TealiumData module.
        static public let tealiumData = "TealiumData"
        /// Module type identifier for ConnectivityData module.
        static public let connectivityData = "ConnectivityData"
        /// Module type identifier for TimeData module.
        static public let timeData = "TimeData"
    }
}

/// The list of modules factories that can be used to instantiate and pass modules to the `TealiumConfig`.
public enum Modules {
}

public extension Modules {
    /**
     * A block with a utility builder that can be used to enforce some of the `ModuleSettings` instead of relying on Local or Remote settings.
     * Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `Module`,
     * other settings will still be affected by Local and Remote settings and updates.
     */
    typealias EnforcingSettings<Builder> = (_ enforcedSettings: Builder) -> Builder

    /**
     * Returns a factory for creating the `AppDataModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     * Omitting this parameter will initialize the module with its default settings.
     */
    static func appData(forcingSettings block: EnforcingSettings<AppDataSettingsBuilder>? = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<AppDataModule>(moduleType: Modules.Types.appData,
                                          enforcedSettings: block?(AppDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `CollectModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     * Omitting this parameter will initialize the module with its default settings.
     */
    static func collect(forcingSettings block: EnforcingSettings<CollectSettingsBuilder>? = { $0 }) -> some ModuleFactory {
        CollectModule.Factory(forcingSettings: [block])
    }

    /**
     * Returns a factory for creating the `CollectModule`.
     *
     * When using this method, be sure to provide different module IDs per each `CollectSettingsBuilder` provided.
     * If multiple builders result in having the same module ID, only the first one will be used.
     * Default module ID will be the `Modules.Types.collect` (`Collect`).
     *
     * - Parameters:
     *   -  block: A block with a utility builder that can be used to enforce some of the `CollectSettings` instead of relying on
     *   Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the
     *   `CollectModule`, other settings will still be affected by Local and Remote settings and updates.
     *   - blocks: Other blocks used to configure additional collect modules.
     */
    static func collect(forcingSettings block: @escaping EnforcingSettings<CollectSettingsBuilder>,
                        _ blocks: EnforcingSettings<CollectSettingsBuilder>...) -> some ModuleFactory {
        CollectModule.Factory(forcingSettings: [block] + blocks)
    }

    /**
     * Returns a factory for creating the `DataLayerModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Omitting this parameter will initialize the module with its default settings.
     */
    static func dataLayer(forcingSettings block: EnforcingSettings<DataLayerSettingsBuilder> = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<DataLayerModule>(moduleType: Modules.Types.dataLayer,
                                            enforcedSettings: block(DataLayerSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `DeviceDataModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     * Omitting this parameter will initialize the module with its default settings.
     */
    static func deviceData(forcingSettings block: EnforcingSettings<DeviceDataSettingsBuilder>? = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<DeviceDataModule>(moduleType: Modules.Types.deviceData,
                                             enforcedSettings: block?(DeviceDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `DeepLinkModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     * Omitting this parameter will initialize the module with its default settings.
     */
    static func deepLink(forcingSettings block: EnforcingSettings<DeepLinkSettingsBuilder>? = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<DeepLinkModule>(moduleType: Modules.Types.deepLink,
                                           enforcedSettings: block?(DeepLinkSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `TealiumDataModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Omitting this parameter will initialize the module with its default settings.
     */
    static func tealiumData(forcingSettings block: EnforcingSettings<TealiumDataSettingsBuilder> = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<TealiumDataModule>(moduleType: Modules.Types.tealiumData,
                                              enforcedSettings: block(TealiumDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `TimeDataModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     * Omitting this parameter will initialize the module with its default settings.
     */
    static func timeData(forcingSettings block: EnforcingSettings<TimeDataSettingsBuilder>? = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<TimeDataModule>(moduleType: Modules.Types.timeData,
                                           enforcedSettings: block?(TimeDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `ConnectivityDataModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     * Omitting this parameter will initialize the module with its default settings.
     */
    static func connectivityData(forcingSettings block: EnforcingSettings<ConnectivityDataSettingsBuilder>? = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<ConnectivityDataModule>(moduleType: Modules.Types.connectivityData,
                                                   enforcedSettings: block?(ConnectivityDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `TraceModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     * Omitting this parameter will initialize the module with its default settings.
     */
    static func trace(forcingSettings block: EnforcingSettings<TraceSettingsBuilder>? = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<TraceModule>(moduleType: Modules.Types.trace,
                                        enforcedSettings: block?(TraceSettingsBuilder()).build())
    }

    /**
     * Adds a `ModuleFactory` to the list of default factories that are added to each `Tealium` instance.
     *
     * Each module added in this list will be added only if the same module wasn't already added in the specific config object.
     * Generally factories added by default will not return any enforced settings, meaning that they will require some local or remote settings
     * to initialize the respective modules.
     *
     * If they contain some settings, instead, their modules will be initialized even if they are not configured elsewhere.
     */
    static func addDefaultModule<SpecificFactory: ModuleFactory>(_ module: SpecificFactory) {
        TealiumQueue.worker.ensureOnQueue {
            ModuleRegistry.shared.addDefaultModule(module)
        }
    }
}
