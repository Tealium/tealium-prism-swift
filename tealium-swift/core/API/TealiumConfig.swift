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
    public internal(set) var settingsFile: String?
    public internal(set) var settingsUrl: String?
    public var modules: [any TealiumModuleFactory]
    public var barriers: [Barrier] = []
    public var transformers: [Transformer] = []
    public var loggerType: TealiumLoggerType = .os
    public var bundle: Bundle = .main
    let coreSettings: [String: Any]?

    public init(account: String, profile: String, environment: String, modules: [any TealiumModuleFactory],
                settingsFile: String?, settingsUrl: String?, forcingSettings block: ((_ builder: CoreSettingsBuilder) -> CoreSettingsBuilder)? = nil) {
        self.account = account
        self.profile = profile
        self.environment = environment
        self.settingsFile = settingsFile
        self.settingsUrl = settingsUrl
        self.modules = modules
        coreSettings = block?(CoreSettingsBuilder()).build()
    }

    func getEnforcedSDKSettings() -> SDKSettings {
        let accumulator = [CoreSettings.id: coreSettings].compactMapValues { $0 }
        let modulesSettings = modules.reduce(into: accumulator) { partialResult, factory in
            guard let moduleEnforcedSettings = factory.getEnforcedSettings() else {
                return
            }
            partialResult[factory.id] = moduleEnforcedSettings
        }
        return SDKSettings(modulesSettings: modulesSettings)
    }

    mutating public func addModule<ModuleFactory: TealiumModuleFactory>(_ module: ModuleFactory) {
        modules.append(module)
    }
}
