//
//  CoreConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//

import Foundation

public struct TealiumConfig {
    public let modules: [TealiumModule.Type]
    private let configFile: String
    private let configUrl: String?
    
    public init(modules: [TealiumModule.Type], configFile: String, configUrl: String?) {
        self.modules = modules
        self.configFile = configFile
        self.configUrl = configUrl
    }
}


// TODO: split TealiumConfig and Core/Module Settings
public class CoreSettings {
    private var dictionary: [String: Any]

    @ToAnyObservable(TealiumReplaySubject<CoreSettings>())
    var onConfigUpdate: TealiumObservable<CoreSettings>
    
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
    
    func updateConfig(_ config: [String: Any]) {
        dictionary = config
        _onConfigUpdate.publish(self)
    }
}
