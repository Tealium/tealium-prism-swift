//
//  ConsentSettingsBuilder.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to enforce some of the ConsentSettings.
public class ConsentSettingsBuilder: ModuleSettingsBuilder {
    typealias Keys = ConsentConfiguration.Keys
    override init() { }

    /// Set the dispatcherToPurposes map
    public func setDispatcherToPurposes(_ dispatcherToPurposes: [String: [String]]) -> Self {
        _configurationObject.set(converting: dispatcherToPurposes, key: Keys.dispatcherToPurposes)
        return self
    }

    /// Set the shouldRefireDispatchers
    public func setShouldRefireDispatchers(_ shouldRefireDispatchers: [String]) -> Self {
        _configurationObject.set(converting: shouldRefireDispatchers, key: Keys.shouldRefireDispatchers)
        return self
    }
}
