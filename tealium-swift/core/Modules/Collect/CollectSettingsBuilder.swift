//
//  CollectSettingsBuilder.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 08/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to enforce some of the `CollectSettings`.
public class CollectSettingsBuilder: ModuleSettingsBuilder {
    typealias Keys = CollectSettings.Keys
    var url: String?
    var batchUrl: String?
    var overrideProfile: String?
    var overrideDomain: String?
    override init() { }
    /// Set the URL used to send single events
    public func setUrl(_ url: String) -> Self {
        self.url = url
        return self
    }

    /// Set the URL used to send a batch of events
    public func setBatchUrl(_ batchUrl: String) -> Self {
        self.batchUrl = batchUrl
        return self
    }

    /// Set the profile used to override the `TealiumConfig.profile` in the event data sent to the collect endpoint
    public func setOverrideProfile(_ overrideProfile: String) -> Self {
        self.overrideProfile = overrideProfile
        return self
    }

    /// Set the domain used to replace the default single event URL and default batch events URL domains.
    /// This won't override URL and batch URL that are provided in the settings.
    public func setOverrideDomain(_ overrideDomain: String) -> Self {
        self.overrideDomain = overrideDomain
        return self
    }

    /// Returns a dictionary with the enforced CollectSettings.
    override public func build() -> [String: Any] {
        let dictionaryWithOptionals: [String: Any?] = [
            Keys.url: url,
            Keys.batchUrl: batchUrl,
            Keys.overrideProfile: overrideProfile,
            Keys.overrideDomain: overrideDomain
        ]
        return dictionaryWithOptionals.compactMapValues { $0 } + super.build()
    }
}
