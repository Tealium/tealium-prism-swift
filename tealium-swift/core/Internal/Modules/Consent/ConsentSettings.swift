//
//  ConsentSettings.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

struct ConsentSettings {
    let dispatcherToPurposes: [String: [String]]
    let shouldRefireDispatchers: [String]
    enum Keys {
        static let dispatcherToPurposes = "dispatcher_to_purposes"
        static let shouldRefireDispatchers = "should_refire_dispatchers"
    }

    init(moduleSettings: [String: Any]) {
        dispatcherToPurposes = moduleSettings[Keys.dispatcherToPurposes] as? [String: [String]] ?? [:]
        shouldRefireDispatchers = moduleSettings[Keys.shouldRefireDispatchers] as? [String] ?? []
    }
}
