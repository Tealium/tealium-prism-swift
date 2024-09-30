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

    init(moduleSettings: DataObject) {
        dispatcherToPurposes = moduleSettings.getDataDictionary(key: Keys.dispatcherToPurposes)?
            .compactMapValues { $0.getArray()?.compactMap { $0 } } ?? [:]
        shouldRefireDispatchers = moduleSettings.getArray(key: Keys.shouldRefireDispatchers)?
            .compactMap { $0 } ?? []
    }
}
