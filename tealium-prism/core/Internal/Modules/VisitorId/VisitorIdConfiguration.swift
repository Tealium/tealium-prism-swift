//
//  VisitorIdConfiguration.swift
//  tealium-prism
//
//  Created by Den Guzov on 25/09/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

struct VisitorIdConfiguration {
    let visitorIdentityKey: String?

    enum Keys {
        static let visitorIdentityKey = "visitor_identity_key"
    }

    enum Defaults {
        static let visitorIdentityKey: String? = nil
    }

    init(configuration: DataObject = [:]) {
        self.init(visitorIdentityKey: configuration.get(key: Keys.visitorIdentityKey) ?? Defaults.visitorIdentityKey)
    }

    init(visitorIdentityKey: String?) {
        self.visitorIdentityKey = visitorIdentityKey
    }
}
