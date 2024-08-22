//
//  SDKSettings.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A container of settings for each module.
public struct SDKSettings: Codable {
    /// A Dictionary of JSON serializable settings for a single module.
    public typealias ModuleSettings = [String: Any]
    /// A Dictionary containing all the settings for each module, keyed by `Module.id`.
    public let modulesSettings: [String: ModuleSettings]
    /// A utility to return a type safe representation of the Core settings, potentially used by all the modules.
    public var coreSettings: CoreSettings {
        CoreSettings(coreDictionary: modulesSettings[CoreSettings.id] ?? [:])
    }

    init(modulesSettings: [String: ModuleSettings]) {
        self.modulesSettings = modulesSettings
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let anyCodable = try container.decode(AnyCodable.self)
        guard let settings = anyCodable.value as? [String: ModuleSettings] else {
            throw ParsingError.jsonIsNotADictionary(anyCodable.value)
        }
        modulesSettings = settings
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(AnyCodable(modulesSettings))
    }
}
