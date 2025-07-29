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
    /// The IDs for the modules
     enum IDs {
        static public let appData = AppDataModule.id
        static public let collect = CollectModule.id
        static public let dataLayer = DataLayerModule.id
        static public let deviceData = DeviceDataModule.id
        static public let trace = TraceModule.id
        static public let deepLink = DeepLinkModule.id
        static public let tealiumData = TealiumDataModule.id
        static public let connectivityData = ConnectivityDataModule.id
        static public let timeData = TimeDataModule.id
    }
}

/// The list of modules factories that can be used to instantiate and pass modules to the `TealiumConfig`.
public enum Modules {

    /// Returns a factory for creating the `AppDataModule`
    static public func appData() -> any ModuleFactory {
        DefaultModuleFactory<AppDataModule>()
    }

    /**
     * Returns a factory for creating the `CollectModule`.
     *
     * - Parameters:
     *   -  block: A block with a utility builder that can be used to enforce some of the `CollectSettings` instead of relying on Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `CollectModule` module, other settings will still be affected by Local and Remote settings and updates.
     */
    static public func collect(forcingSettings block: ((_ enforcedSettings: CollectSettingsBuilder) -> CollectSettingsBuilder)? = nil) -> any ModuleFactory {
        CollectModule.Factory(forcingSettings: block)
    }

    /// Returns a factory for creating the `DataLayerModule`.
    static func dataLayer() -> any ModuleFactory {
        DefaultModuleFactory<DataLayerModule>()
    }

    /// Returns a factory for creating the `DeviceDataModule`.
    static public func deviceData(forcingSettings block: ((_ enforcedSettings: DeviceDataSettingsBuilder) -> DeviceDataSettingsBuilder)? = nil) -> any ModuleFactory {
        DeviceDataModule.Factory(forcingSettings: block)
    }

    /// Returns a factory for creating the `DeepLinkModule`.
    static public func deepLink(forcingSettings block: ((_ enforcedSettings: DeepLinkSettingsBuilder) -> DeepLinkSettingsBuilder)? = nil) -> any ModuleFactory {
        DeepLinkModule.Factory(forcingSettings: block)
    }

    /// Returns a factory for creating the `TealiumDataModule`.
    static public func tealiumData() -> any ModuleFactory {
        DefaultModuleFactory<TealiumDataModule>()
    }

    /// Returns a factory for creating the `TimeDataModule`.
    static public func timeData() -> any ModuleFactory {
        DefaultModuleFactory<TimeDataModule>()
    }

    /// Returns a factory for creating the `ConnectivityDataModule`.
    static public func connectivityData() -> any ModuleFactory {
        DefaultModuleFactory<ConnectivityDataModule>()
    }

    /// Returns a factory for creating the `TraceModule`.
    static public func trace(forcingSettings block: ((_ enforcedSettings: CollectorSettingsBuilder) -> CollectorSettingsBuilder)? = nil) -> any ModuleFactory {
        TraceModule.Factory(forcingSettings: block)
    }

    /**
     * Returns a factory for creating a custom Dispatcher.
     *
     * - Parameters:
     *   - module: The `TealiumBasicModule & Dispatcher` that will be created by this factory.
     *   - enforcedSettings: The settings that will remain constant on initialization and on future settings updates for this module.
     */
    static public func customDispatcher<Module: BasicModule & Dispatcher>(_ module: Module.Type, enforcedSettings: DataObject? = nil) -> any ModuleFactory {
        DefaultModuleFactory<Module>(enforcedSettings: enforcedSettings)
    }

    /**
     * Returns a factory for creating a custom Collector.
     *
     * - Parameters:
     *   - module: The `TealiumBasicModule & Collector` that will be created by this factory.
     *   - enforcedSettings: The settings that will remain constant on initialization and on future settings updates for this module.
     */
    static public func customCollector<Module: BasicModule & Collector>(_ module: Module.Type, enforcedSettings: DataObject? = nil) -> any ModuleFactory {
        DefaultModuleFactory<Module>(enforcedSettings: enforcedSettings)
    }
}

/// A basic factory that can be reused to create modules that have no extra dependencies and don't need utility for settings builders.
public class DefaultModuleFactory<Module: BasicModule>: ModuleFactory {
    let enforcedSettings: DataObject?

    /// - parameter enforcedSettings: The `DataObject` representation of the full `ModuleSettings` object
    public init(enforcedSettings: DataObject? = nil) {
        self.enforcedSettings = enforcedSettings
    }

    public func create(context: TealiumContext, moduleConfiguration: DataObject) -> Module? {
        Module(context: context, moduleConfiguration: moduleConfiguration)
    }

    public func getEnforcedSettings() -> DataObject? {
        enforcedSettings
    }
}
