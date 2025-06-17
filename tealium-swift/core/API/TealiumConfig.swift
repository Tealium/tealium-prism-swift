//
//  TealiumConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public struct TealiumConfig {
    public let account: String
    public let profile: String
    public let environment: String
    public let dataSource: String?
    public var key: String { "\(account)-\(profile)" }
    public internal(set) var settingsFile: String?
    public internal(set) var settingsUrl: String?
    public internal(set) var modules: [any TealiumModuleFactory]
    public internal(set) var barriers: [any BarrierFactory] = []
    public var loggerType: TealiumLoggerType = .os
    public var bundle: Bundle = .main
    public var existingVisitorId: String?
    public var cmpAdapter: CMPAdapter?
    let coreSettings: DataObject?
    var consentSettings: DataObject?
    var loadRules = DataObject()
    var transformations = DataObject()

    public init(account: String, profile: String, environment: String, dataSource: String? = nil, modules: [any TealiumModuleFactory],
                settingsFile: String?, settingsUrl: String?, forcingSettings block: ((_ builder: CoreSettingsBuilder) -> CoreSettingsBuilder)? = nil) {
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
        let modulesSettings = modules.reduce(into: [String: DataObject]()) { partialResult, factory in
            guard let moduleEnforcedSettings = factory.getEnforcedSettings() else {
                return
            }
            partialResult[factory.id] = moduleEnforcedSettings
        }
        // TODO: Add barriers
        if let coreSettings {
            accumulator.set(converting: coreSettings, key: SDKSettings.Keys.core)
        }
        if !modulesSettings.isEmpty {
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

    mutating public func addModule<ModuleFactory: TealiumModuleFactory>(_ module: ModuleFactory) {
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
     *      - block: An optional block called with a configuration builder, used to force some of the `ConsentConfiguration` properties. Properties set with this block will have precedence to local and remote settings.
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
