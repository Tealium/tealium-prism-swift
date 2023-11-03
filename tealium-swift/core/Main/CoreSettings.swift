//
//  CoreConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

// TODO: is this supposed to be in the config or not?
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
    var minLogLevel: TealiumLogLevel.Minimum {
        guard let logLevelString = dictionary["minLogLevel"] as? String,
              let level = TealiumLogLevel.Minimum(from: logLevelString) else {
            return .default
        }
        return level
    }
}
