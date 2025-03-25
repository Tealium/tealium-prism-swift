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
    typealias Keys = CollectConfiguration.Keys
    override init() { }
    /// Set the URL used to send single events
    public func setUrl(_ url: String) -> Self {
        _configurationObject.set(url, key: Keys.url)
        return self
    }

    /// Set the URL used to send a batch of events
    public func setBatchUrl(_ batchUrl: String) -> Self {
        _configurationObject.set(batchUrl, key: Keys.batchUrl)
        return self
    }

    /// Set the profile used to override the `TealiumConfig.profile` in the event data sent to the collect endpoint
    public func setOverrideProfile(_ overrideProfile: String) -> Self {
        _configurationObject.set(overrideProfile, key: Keys.overrideProfile)
        return self
    }

    /// Set the domain used to replace the default single event URL and default batch events URL domains.
    /// This won't override URL and batch URL that are provided in the settings.
    public func setOverrideDomain(_ overrideDomain: String) -> Self {
        _configurationObject.set(overrideDomain, key: Keys.overrideDomain)
        return self
    }
}
