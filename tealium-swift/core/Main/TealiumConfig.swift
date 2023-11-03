//
//  TealiumConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public struct TealiumConfig {
    public var modules: [TealiumModule.Type]
    public var loggerType: TealiumLoggerType = .os
    public let configFile: String
    private let configUrl: String?

    public init(modules: [TealiumModule.Type], configFile: String, configUrl: String?) {
        self.modules = modules
        self.configFile = configFile
        self.configUrl = configUrl
    }
}
