//
//  Modules.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 08/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
// some ModuleFactory is possible as return types for all of these methods
// but won't compile for iOS < 13 on Intel machines so any is used instead

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

    /**
     * A block with a utility builder that can be used to enforce some of the `ModuleSettings` instead of relying on Local or Remote settings.
     * Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `Module`,
     * other settings will still be affected by Local and Remote settings and updates.
     */
    public typealias EnforcingSettings<Builder> = (_ enforcedSettings: Builder) -> Builder

    /// Returns a factory for creating the `AppDataModule`
    static public func appData(forcingSettings block: EnforcingSettings<CollectorSettingsBuilder>? = nil) -> any ModuleFactory {
        DefaultModuleFactory<AppDataModule>(moduleType: Modules.Types.appData,
                                            enforcedSettings: block?(CollectorSettingsBuilder()).build())
    }

    /**
     * Returns a factory for creating the `CollectModule`.
     *
     * - Parameters:
     *   -  block: A block with a utility builder that can be used to enforce some of the `CollectSettings` instead of relying on
     *   Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the
     *   `CollectModule`, other settings will still be affected by Local and Remote settings and updates.
     */
    static public func collect(forcingSettings blocks: EnforcingSettings<CollectSettingsBuilder>...) -> any ModuleFactory {
        CollectModule.Factory(forcingSettings: blocks)
    }

    /// Returns a factory for creating the `DataLayerModule`.
    static public func dataLayer(forcingSettings block: EnforcingSettings<CollectorSettingsBuilder>? = nil) -> any ModuleFactory {
        DefaultModuleFactory<DataLayerModule>(moduleType: Modules.Types.dataLayer,
                                              enforcedSettings: block?(CollectorSettingsBuilder()).build())
    }

    /// Returns a factory for creating the `DeviceDataModule`.
    static public func deviceData(forcingSettings block: EnforcingSettings<DeviceDataSettingsBuilder>? = nil) -> any ModuleFactory {
        DefaultModuleFactory<DeviceDataModule>(moduleType: Modules.Types.deviceData,
                                               enforcedSettings: block?(DeviceDataSettingsBuilder()).build())
    }

    /// Returns a factory for creating the `DeepLinkModule`.
    static public func deepLink(forcingSettings block: EnforcingSettings<DeepLinkSettingsBuilder>? = nil) -> any ModuleFactory {
        DefaultModuleFactory<DeepLinkModule>(moduleType: Modules.Types.deepLink,
                                             enforcedSettings: block?(DeepLinkSettingsBuilder()).build())
    }

    /// Returns a factory for creating the `TealiumDataModule`.
    static public func tealiumData(forcingSettings block: EnforcingSettings<CollectorSettingsBuilder>? = nil) -> any ModuleFactory {
        DefaultModuleFactory<TealiumDataModule>(moduleType: Modules.Types.tealiumData,
                                                enforcedSettings: block?(CollectorSettingsBuilder()).build())
    }

    /// Returns a factory for creating the `TimeDataModule`.
    static public func timeData(forcingSettings block: EnforcingSettings<CollectorSettingsBuilder>? = nil) -> any ModuleFactory {
        DefaultModuleFactory<TimeDataModule>(moduleType: Modules.Types.timeData,
                                             enforcedSettings: block?(CollectorSettingsBuilder()).build())
    }

    /// Returns a factory for creating the `ConnectivityDataModule`.
    static public func connectivityData(forcingSettings block: EnforcingSettings<CollectorSettingsBuilder>? = nil) -> any ModuleFactory {
        DefaultModuleFactory<ConnectivityDataModule>(moduleType: Modules.Types.connectivityData,
                                                     enforcedSettings: block?(CollectorSettingsBuilder()).build())
    }

    /// Returns a factory for creating the `TraceModule`.
    static public func trace(forcingSettings block: EnforcingSettings<CollectorSettingsBuilder>? = nil) -> any ModuleFactory {
        DefaultModuleFactory<TraceModule>(moduleType: Modules.Types.trace,
                                          enforcedSettings: block?(CollectorSettingsBuilder()).build())
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
