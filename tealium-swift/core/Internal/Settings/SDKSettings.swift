//
//  SDKSettings.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A container of settings for each module.
struct SDKSettings: Codable {
    /// A Dictionary containing all the settings for each module, keyed by `Module.id`.
    let modulesSettings: [String: DataObject]
    /// A utility to return a type safe representation of the Core settings, potentially used by all the modules.
    var coreSettings: CoreSettings {
        CoreSettings(coreDataObject: modulesSettings[CoreSettings.id] ?? [:])
    }

    init(modulesSettings: [String: DataObject]) {
        self.modulesSettings = modulesSettings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        modulesSettings = try container.decode([String: DataObject].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(modulesSettings)
    }
}
