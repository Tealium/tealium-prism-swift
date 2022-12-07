//
//  CoreConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//

import Foundation


// TODO: split TealiumConfig and Core/Module Settings
public class CoreConfig {
    public var modules: [TealiumModule.Type]
    private var dictionary: [String: Any]

    @ToAnyObservable(TealiumReplaySubject<CoreConfig>())
    var onConfigUpdate: TealiumObservable<CoreConfig>
    
    public init(modules: [TealiumModule.Type],
                coreDictionary: [String: Any]) {
        self.modules = modules
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
