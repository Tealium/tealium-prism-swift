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
    public var modules: [TealiumModule.Type]
    public var barriers: [Barrier] = []
    public var transformers: [Transformer] = []
    public var loggerType: TealiumLoggerType = .os
    public let configFile: String
    public let configUrl: String?

    public init(account: String, profile: String, environment: String, modules: [TealiumModule.Type], configFile: String, configUrl: String?) {
        self.account = account
        self.profile = profile
        self.environment = environment
        self.modules = modules
        self.configFile = configFile
        self.configUrl = configUrl
    }
}
