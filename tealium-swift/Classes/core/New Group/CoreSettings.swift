//
//  CoreConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//

import Foundation

public struct TealiumConfig {
    public var modules: [TealiumModule.Type]
    public let configFile: String
    private let configUrl: String?
    
    public init(modules: [TealiumModule.Type], configFile: String, configUrl: String?) {
        self.modules = modules
        self.configFile = configFile
        self.configUrl = configUrl
    }
}

// TODO: Evaluate generic module settings


// TODO: split TealiumConfig and Core/Module Settings
public struct CoreSettings {
    private var dictionary: [String: Any]
    
    public init(coreDictionary: [String: Any]) {
        self.dictionary = coreDictionary
    }
    
    var account: String? {
        dictionary["account"] as? String
    }
    var profile: String? {
        dictionary["profile"] as? String
    }
    var environment: String? {
        dictionary["environment"] as? String
    }
    
    mutating func updateSettings(_ config: [String: Any]) {
        dictionary = config
    }
}
