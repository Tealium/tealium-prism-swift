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
        static public let appData = AppDataCollector.id
        static public let collect = CollectDispatcher.id
        static public let dataLayer = DataLayerModule.id
        static public let deviceData = DeviceDataCollector.id
        static public let trace = TraceManagerModule.id
        static public let deepLink = DeepLinkHandlerModule.id
        static public let tealiumCollector = TealiumCollector.id
        static public let connectivityCollector = ConnectivityCollector.id
        static public let timeCollector = TimeCollector.id
    }
}

/// The list of modules factories that can be used to instantiate and pass modules to the `TealiumConfig`.
public enum Modules {

    /// Returns a factory for creating the `AppDataCollector`
    static public func appData() -> any ModuleFactory {
        DefaultModuleFactory<AppDataCollector>()
    }

    /**
     * Returns a factory for creating the `CollectDispatcher`.
     *
     * - Parameters:
     *   -  block: A block with a utility builder that can be used to enforce some of the `CollectSettings` instead of relying on Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `CollectDispatcher` module, other settings will still be affected by Local and Remote settings and updates.
     */
    static public func collect(forcingSettings block: ((_ enforcedSettings: CollectSettingsBuilder) -> CollectSettingsBuilder)? = nil) -> any ModuleFactory {
        CollectDispatcher.Factory(forcingSettings: block)
    }

    /// Returns a factory for creating the `DataLayerModule`.
    static func dataLayer() -> any ModuleFactory {
        DefaultModuleFactory<DataLayerModule>()
    }

    /// Returns a factory for creating the `DeviceDataCollector`.
    static public func deviceData(forcingSettings block: ((_ enforcedSettings: DeviceDataSettingsBuilder) -> DeviceDataSettingsBuilder)? = nil) -> any ModuleFactory {
        DeviceDataCollector.Factory(forcingSettings: block)
    }

    /// Returns a factory for creating the `DeepLinkModule`.
    static public func deepLink(forcingSettings block: ((_ enforcedSettings: DeepLinkSettingsBuilder) -> DeepLinkSettingsBuilder)? = nil) -> any ModuleFactory {
        DeepLinkHandlerModule.Factory(forcingSettings: block)
    }

    /// Returns a factory for creating the `TealiumCollector`.
    static public func tealiumCollector() -> any ModuleFactory {
        DefaultModuleFactory<TealiumCollector>()
    }

    /// Returns a factory for creating the `TimeCollector`.
    static public func timeCollector() -> any ModuleFactory {
        DefaultModuleFactory<TimeCollector>()
    }

    /// Returns a factory for creating the `ConnectivityCollector`.
    static public func connectivityCollector() -> any ModuleFactory {
        DefaultModuleFactory<ConnectivityCollector>()
    }

    /// Returns a factory for creating the `TraceModule`.
    static public func trace(forcingSettings block: ((_ enforcedSettings: CollectorSettingsBuilder) -> CollectorSettingsBuilder)? = nil) -> any ModuleFactory {
        TraceManagerModule.Factory(forcingSettings: block)
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
