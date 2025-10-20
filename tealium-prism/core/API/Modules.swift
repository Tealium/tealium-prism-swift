//
//  Modules.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 08/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

// TODO: fix this when we switch to iOS 13.
// some ModuleFactory is possible as return types for all of these methods
// but won't compile for iOS < 13 on Intel machines so any is used instead.

public extension Modules {
    /// The Types for the modules
     enum Types {
         static public let appData = "AppData"
         static public let collect = "Collect"
         static public let dataLayer = "DataLayer"
         static public let deviceData = "DeviceData"
         static public let trace = "Trace"
         static public let deepLink = "DeepLink"
         static public let tealiumData = "TealiumData"
         static public let connectivityData = "ConnectivityData"
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
     */
    static func appData(forcingSettings block: EnforcingSettings<AppDataSettingsBuilder>? = { $0 }) -> any ModuleFactory {
        DefaultModuleFactory<AppDataModule>(moduleType: Modules.Types.appData,
                                            enforcedSettings: block?(AppDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `CollectModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     */
    static func collect(forcingSettings block: EnforcingSettings<CollectSettingsBuilder>? = { $0 }) -> any ModuleFactory {
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
                        _ blocks: EnforcingSettings<CollectSettingsBuilder>...) -> any ModuleFactory {
        CollectModule.Factory(forcingSettings: [block] + blocks)
    }

    /**
     * Returns a factory for creating the `DataLayerModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     */
    static func dataLayer(forcingSettings block: EnforcingSettings<DataLayerSettingsBuilder> = { $0 }) -> any ModuleFactory {
        DefaultModuleFactory<DataLayerModule>(moduleType: Modules.Types.dataLayer,
                                              enforcedSettings: block(DataLayerSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `DeviceDataModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     */
    static func deviceData(forcingSettings block: EnforcingSettings<DeviceDataSettingsBuilder>? = { $0 }) -> any ModuleFactory {
        DefaultModuleFactory<DeviceDataModule>(moduleType: Modules.Types.deviceData,
                                               enforcedSettings: block?(DeviceDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `DeepLinkModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     */
    static func deepLink(forcingSettings block: EnforcingSettings<DeepLinkSettingsBuilder>? = { $0 }) -> any ModuleFactory {
        DefaultModuleFactory<DeepLinkModule>(moduleType: Modules.Types.deepLink,
                                             enforcedSettings: block?(DeepLinkSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `TealiumDataModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     */
    static func tealiumData(forcingSettings block: EnforcingSettings<TealiumDataSettingsBuilder> = { $0 }) -> any ModuleFactory {
        DefaultModuleFactory<TealiumDataModule>(moduleType: Modules.Types.tealiumData,
                                                enforcedSettings: block(TealiumDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `TimeDataModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     */
    static func timeData(forcingSettings block: EnforcingSettings<TimeDataSettingsBuilder>? = { $0 }) -> any ModuleFactory {
        DefaultModuleFactory<TimeDataModule>(moduleType: Modules.Types.timeData,
                                             enforcedSettings: block?(TimeDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `ConnectivityDataModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     */
    static func connectivityData(forcingSettings block: EnforcingSettings<ConnectivityDataSettingsBuilder>? = { $0 }) -> any ModuleFactory {
        DefaultModuleFactory<ConnectivityDataModule>(moduleType: Modules.Types.connectivityData,
                                                     enforcedSettings: block?(ConnectivityDataSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `TraceModule`.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     * Pass `nil` to initialize this module only when some Local or Remote settings are provided.
     */
    static func trace(forcingSettings block: EnforcingSettings<TraceSettingsBuilder>? = { $0 }) -> any ModuleFactory {
        DefaultModuleFactory<TraceModule>(moduleType: Modules.Types.trace,
                                          enforcedSettings: block?(TraceSettingsBuilder()).build())
    }
}

/// A basic factory that can be reused to create modules that have no extra dependencies and can only be initialized once.
class DefaultModuleFactory<Module: BasicModule>: ModuleFactory {
    let enforcedSettings: [DataObject]
    let moduleType: String
    let allowsMultipleInstances: Bool = false

    init(moduleType: String, enforcedSettings: DataObject? = nil) {
        self.moduleType = moduleType
        self.enforcedSettings = [enforcedSettings].compactMap { $0 }
    }

    func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> Module? {
        Module(context: context, moduleConfiguration: moduleConfiguration)
    }

    func getEnforcedSettings() -> [DataObject] {
        enforcedSettings
    }
}
