//
//  TraceModuleConfiguration.swift
//  tealium-prism
//
//  Created by Den Guzov on 21/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct TraceModuleConfiguration {
    let trackErrors: Bool

    enum Keys {
        static let trackErrors = "track_errors"
    }

    enum Defaults {
        static let trackErrors: Bool = false
    }

    init(configuration: DataObject = [:]) {
        self.init(trackErrors: configuration.get(key: Keys.trackErrors) ?? Defaults.trackErrors)
    }

    init(trackErrors: Bool) {
        self.trackErrors = trackErrors
    }
}
