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
        var accumulator = [CoreSettings.id: coreSettings].compactMapValues { $0 }
        let modulesSettings = modules.reduce(into: [String: DataObject]()) { partialResult, factory in
            guard let moduleEnforcedSettings = factory.getEnforcedSettings() else {
                return
            }
            partialResult[factory.id] = moduleEnforcedSettings
        }
        // TODO: Add load rules and stuff?
        if !modulesSettings.isEmpty {
            accumulator["modules"] = DataObject(dictionary: modulesSettings)
        }
        return DataObject(dictionary: accumulator)
    }

    mutating public func addModule<ModuleFactory: TealiumModuleFactory>(_ module: ModuleFactory) {
        modules.append(module)
    }
}
