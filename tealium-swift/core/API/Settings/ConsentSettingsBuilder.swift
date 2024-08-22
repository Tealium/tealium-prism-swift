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
    typealias Keys = ConsentSettings.Keys
    var dispatcherToPurposes: [String: [String]]?
    var shouldRefireDispatchers: [String]?
    override init() { }

    /// Set the dispatcherToPurposes map
    public func setDispatcherToPurposes(_ dispatcherToPurposes: [String: [String]]) -> Self {
        self.dispatcherToPurposes = dispatcherToPurposes
        return self
    }

    /// Set the shouldRefireDispatchers
    public func setShouldRefireDispatchers(_ shouldRefireDispatchers: [String]) -> Self {
        self.shouldRefireDispatchers = shouldRefireDispatchers
        return self
    }

    /// Returns a dictionary with the enforced ConsentSettings.
    override public func build() -> [String: Any] {
        let dictionaryWithOptionals: [String: Any?] = [
            Keys.dispatcherToPurposes: dispatcherToPurposes,
            Keys.shouldRefireDispatchers: shouldRefireDispatchers
        ]
        return dictionaryWithOptionals.compactMapValues { $0 } + super.build()
    }
}
