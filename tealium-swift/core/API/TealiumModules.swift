//
//  TealiumModules.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 08/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
// some TealiumModuleFactory is possible as return types for all of these methods
// but won't compile for iOS < 13 on Intel machines so any is used instead

/// The list of modules factories that can be used to instanciate and pass modules to the `TealiumConfig`.
public enum TealiumModules {

    /// Returns a factory for creating the `AppDataCollector`
    static public func appData() -> any TealiumModuleFactory {
        DefaultModuleFactory<AppDataCollector>()
    }

    /**
     * Returns a factory for creating the `TealiumCollect` dispatcher.
     *
     * - Parameters:
     *   -  block: A block with a utility builder that can be used to enforce some of the `CollectSettings` instead of relying on Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `TealiumCollect` module, other settings will still be affected by Local and Remote settings and updates.
     */
    static public func collect(forcingSettings block: ((_ enforcedSettings: CollectSettingsBuilder) -> CollectSettingsBuilder)? = nil) -> any TealiumModuleFactory {
        TealiumCollect.Factory(forcingSettings: block)
    }

    /**
     * Returns a factory for creating the `ConsentModule`.
     *
     * - Parameters:
     *    - cmpIntegration: The integration that provides the module with the CMP data to guide the consent management decisions.
     *    - block: A block with a utility builder that can be used to enforce some of the `ConsentSettings` instead of relying on Local or Remote settings. Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `ConsentModule`, other settings will still be affected by Local and Remote settings and updates.
     */
    static public func consent(cmpIntegration: CMPIntegration,
                               forcingSettings block: ((_ enforcedSettings: ConsentSettingsBuilder) -> ConsentSettingsBuilder)? = nil) -> any TealiumModuleFactory {
        ConsentModule.Factory(cmpIntegration: cmpIntegration, forcingSettings: block)
    }

    /// Returns a factory for creating the `DataLayerModule`.
    static func dataLayer() -> any TealiumModuleFactory {
        DefaultModuleFactory<DataLayerModule>()
    }

    /// Returns a factory for creating the `DeepLinkModule`.
    static public func deepLink(forcingSettings block: ((_ enforcedSettings: DeepLinkSettingsBuilder) -> DeepLinkSettingsBuilder)? = nil) -> any TealiumModuleFactory {
        DeepLinkHandlerModule.Factory(forcingSettings: block)
    }

    /// Returns a factory for creating the `TealiumCollector`.
    static public func tealiumCollector() -> any TealiumModuleFactory {
        DefaultModuleFactory<TealiumCollector>()
    }

    /// Returns a factory for creating the `TimeCollector`.
    static public func timeCollector() -> any TealiumModuleFactory {
        DefaultModuleFactory<TimeCollector>()
    }

    /// Returns a factory for creating the `ConnectivityCollector`.
    static public func connectivityCollector() -> any TealiumModuleFactory {
        DefaultModuleFactory<ConnectivityCollector>()
    }

    /// Returns a factory for creating the `TraceModule`.
    static public func trace(forcingSettings block: ((_ enforcedSettings: CollectorSettingsBuilder) -> CollectorSettingsBuilder)? = nil) -> any TealiumModuleFactory {
        TraceManagerModule.Factory(forcingSettings: block)
    }

    /**
     * Returns a factory for creating a custom Dispatcher.
     *
     * - Parameters:
     *   - module: The `TealiumBasicModule & Dispatcher` that will be created by this factory.
     *   - enforcedSettings: The settings that will remain constant on initialization and on future settings updates for this module.
     */
    static public func customDispatcher<Module: TealiumBasicModule & Dispatcher>(_ module: Module.Type, enforcedSettings: DataObject? = nil) -> any TealiumModuleFactory {
        DefaultModuleFactory<Module>(enforcedSettings: enforcedSettings)
    }

    /**
     * Returns a factory for creating a custom Collector.
     *
     * - Parameters:
     *   - module: The `TealiumBasicModule & Collector` that will be created by this factory.
     *   - enforcedSettings: The settings that will remain constant on initialization and on future settings updates for this module.
     */
    static public func customCollector<Module: TealiumBasicModule & Collector>(_ module: Module.Type, enforcedSettings: DataObject? = nil) -> any TealiumModuleFactory {
        DefaultModuleFactory<Module>(enforcedSettings: enforcedSettings)
    }
}

/// A basic factory that can be reused to create modules that have no extra dependencies and don't need utility for settings builders.
public class DefaultModuleFactory<Module: TealiumBasicModule>: TealiumModuleFactory {
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
