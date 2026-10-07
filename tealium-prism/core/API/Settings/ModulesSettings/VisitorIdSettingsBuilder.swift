//
//  VisitorIdSettingsBuilder.swift
//  tealium-prism
//
//  Created by Den Guzov on 25/09/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to enforce `VisitorIdSettings`.
public class VisitorIdSettingsBuilder: CollectorSettingsBuilder {
    typealias Keys = VisitorIdConfiguration.Keys

    /**
     * Set the key to look for in the data layer when identifying a user.
     *
     * When a value is stored at this key in the data layer, it is taken as the identity of the
     * current user and is used to automatically switch the visitor ID: a previously seen identity
     * restores the visitor ID it was last associated with, a new identity is associated with a
     * visitor ID of its own.
     *
     * Visitor Switching is disabled while no key is configured.
     *
     * - Parameter key: The data layer key that holds the identity of the current user.
     * - Returns: The builder instance for method chaining.
     */
    public func setVisitorIdentityKey(_ key: String) -> Self {
        _configurationObject.set(key, key: Keys.visitorIdentityKey)
        return self
    }
}
