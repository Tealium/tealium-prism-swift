//
//  TealiumConfig.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * The object used to configure a `Tealium` instance with constant values and dependencies.
 */
public struct TealiumConfig {
    /// The Tealium account
    public let account: String

    /// The Tealium profile for the given account
    public let profile: String

    /// The environment, typically prod/qa/dev
    public let environment: String

    /// The datasource for the data coming from this SDK
    public let dataSource: String?

    /// A key used to uniquely identify `Tealium` instances.
    public var key: String { "\(account)-\(profile)" }

    /// The file name from which to read the Local JSON settings.
    /// These settings will be deep merged with Remote and Programmatic settings, which will take priority over Local settings.
    public internal(set) var settingsFile: String?

    /// The URL from which to download Remote settings.
    /// These settings will be deep merged with Local and Programmatic settings.
    /// Programmatic settings will take priority over Remote settings, Remote settings will take priority over Local settings.
    public internal(set) var settingsUrl: String?

    /// A list of unique `ModuleFactory`s, each one for creating a specific `Module`.
    public internal(set) var modules: [any ModuleFactory]

    /// A list of unique `BarrierFactory`s, each one for creating a specific `ConfigurableBarrier`
    public internal(set) var barriers: [any BarrierFactory] = []

    /// A type of logger that can handle logs of different level
    public var loggerType: TealiumLoggerType = .os

    /// The specific bundle in which to look for objects like the Local settings.
    public var bundle: Bundle = .main

    /// A visitor ID to be used instead of our anonymous visitor ID.
    public var existingVisitorId: String?

    /// An adapter that can convert CMP specific data to a `ConsentDecision` that the `Tealium` consent integration system can handle.
    public var cmpAdapter: CMPAdapter?
    /// Replace with nil in tests to use in memory DB
    var databaseName: String? = "tealium"
    var appStatusListener = ApplicationStatusListener.shared
    let coreSettings: DataObject?
    var consentSettings: DataObject?
    var loadRules = DataObject()
    var transformations = DataObject()
    // this is lazy to allow creation of ConnectionManager from the right thread
    lazy var networkClient: NetworkClient = HTTPClient.shared

    /// Creates a new Tealium configuration.
    /// - Parameters:
    ///   - account: The Tealium account identifier.
    ///   - profile: The Tealium profile identifier.
    ///   - environment: The environment (dev, qa, prod).
    ///   - dataSource: Optional data source identifier.
    ///   - modules: Array of module factories to initialize.
    ///   - settingsFile: Optional local settings file name.
    ///   - settingsUrl: Optional remote settings URL.
    ///   - block: Optional block for forcing core settings.
    public init(account: String,
                profile: String,
                environment: String,
                dataSource: String? = nil,
                modules: [any ModuleFactory] = [],
                settingsFile: String? = nil,
                settingsUrl: String? = nil,
                forcingSettings block: ((_ builder: CoreSettingsBuilder) -> CoreSettingsBuilder)? = nil) {
        self.account = account
        self.profile = profile
        self.environment = environment
        self.dataSource = dataSource
        self.settingsFile = settingsFile
        self.settingsUrl = settingsUrl
        self.modules = modules
        coreSettings = block?(CoreSettingsBuilder()).build()
    }

    func getEnforcedSDKSettings() -> DataObject {
        var accumulator = DataObject()
        let modulesSettingsKeyValue: [(moduleId: String, moduleSettings: DataObject)] = modules.flatMap { factory in
            factory.getEnforcedSettings().map { moduleSettings in
                var moduleSettings = moduleSettings
                moduleSettings.set(factory.moduleType, key: ModuleSettings.Keys.moduleType)
                return (moduleSettings.get(key: ModuleSettings.Keys.moduleId) ?? factory.moduleType, moduleSettings)
            }
        }
        // TODO: Add barriers
        if let coreSettings {
            accumulator.set(converting: coreSettings, key: SDKSettings.Keys.core)
        }
        if !modulesSettingsKeyValue.isEmpty {
            let modulesSettings = [String: DataObject](modulesSettingsKeyValue, prefersFirst: true)
            accumulator.set(converting: modulesSettings, key: SDKSettings.Keys.modules)
        }
        if !loadRules.keys.isEmpty {
            accumulator.set(converting: loadRules, key: SDKSettings.Keys.loadRules)
        }
        if !transformations.keys.isEmpty {
            accumulator.set(converting: transformations, key: SDKSettings.Keys.transformations)
        }

        if let consent = consentSettings, !consent.keys.isEmpty {
            accumulator.set(converting: consent, key: SDKSettings.Keys.consent)
        }
        return accumulator
    }

    /**
     * Adds a `ModuleFactory` to the list of modules that need to be instantiated by the SDK.
     *
     * You can add a `ModuleFactory` for a specific `Module` only once. Adding two of them will result in all but the first to be discarded.
     * Some specific `ModuleFactory`, like `Modules.collect()` can potentially instantiate more than one `Collect` module,
     * if they are provided with multiple settings and different `Module` IDs, but the factory still only needs to be added once.
     *
     * - parameter module: The unique `ModuleFactory` used to create a specific type of `Module`.
     */
    mutating public func addModule<SpecificFactory: ModuleFactory>(_ module: SpecificFactory) {
        modules.append(module)
    }

    /**
     * Sets a load rule to be used by any of the modules by the rule's key.
     *
     * - Parameters:
     *      - rule: The `Rule<Condition>` that defines when that rule should match a payload.
     *      - loadRuleId: The id used to look up this specific rule when defining it in the `ModuleSettings`
     */
    mutating public func setLoadRule(_ rule: Rule<Condition>, forId loadRuleId: String) {
        loadRules.set([
            LoadRule.Keys.id: loadRuleId,
            LoadRule.Keys.conditions: rule.toDataInput()
        ], key: loadRuleId)
    }

    /**
     * Sets a transformation to be used by a specific transformer.
     *
     * The transformation ID and transformer ID will be combined and need to be unique or the newer transformation will replace older ones.
     *
     * - Parameters:
     *      - transformation: The `TransformationSettings` that defines which `Transformer` should handle this transformation and how.
     */
    mutating public func setTransformation(_ transformation: TransformationSettings) {
        transformations.set(converting: transformation,
                            key: "\(transformation.transformerId)-\(transformation.id)")
    }

    /**
     * Adds a `BarrierFactory` that will create a `ConfigurableBarrier` to control the flow of dispatches to the `Dispatcher`s.
     *
     * - Parameters:
     *      - barrier: The `BarrierFactory` that can create a specific `ConfigurableBarrier`.
     */
    mutating public func addBarrier(_ barrier: any BarrierFactory) {
        barriers.append(barrier)
    }

    /**
     * Enable consent integration with a `CMPAdapter`.
     *
     * If you enable consent integration events will only be tracked after the `CMPAdapter` returns a `ConsentDecision`,
     * And only after a `ConsentConfiguration` is found for that adapter.
     *
     * Make sure to properly configure consent either locally, remotely or programmatically
     * for the provided `CMPAdapter` to ensure proper tracking.
     *
     * - Parameters:
     *      - cmpAdapter: The adapter that will report the `ConsentDecision` to the SDK
     *      - block: An optional block called with a configuration builder, used to force some of the `ConsentConfiguration` properties.
     *      Properties set with this block will have precedence to local and remote settings.
     */
    mutating public func enableConsentIntegration(with cmpAdapter: CMPAdapter,
                                                  forcingConfiguration block: ((_ enforcedConfiguration: ConsentConfigurationBuilder) -> ConsentConfigurationBuilder)? = nil) {
        self.cmpAdapter = cmpAdapter
        if let configuration = block?(ConsentConfigurationBuilder()) {
            consentSettings = ConsentSettingsBuilder(vendorId: cmpAdapter.id)
                .setConfiguration(configuration)
                .build()
        }
    }
}
