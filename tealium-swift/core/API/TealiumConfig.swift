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
    public var modules: [any TealiumModuleFactory]
    public var barriers: [Barrier] = []
    public var loggerType: TealiumLoggerType = .os
    public var bundle: Bundle = .main
    public var existingVisitorId: String?
    let coreSettings: DataObject?
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
        // TODO: Add transformations and barriers
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
}
