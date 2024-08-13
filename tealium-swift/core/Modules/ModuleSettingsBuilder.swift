//
//  ModuleSettingsBuilder.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A base class that adds the enabled setter for SettingsBuilders that are Optional and therefore can be disabled.
open class ModuleSettingsBuilder {
    public static let enabledKey = "enabled"
    public private(set) var enabled: Bool?
    public init() { }
    /// Set the enabled flag for these settings.
    public func setEnabled(_ enabled: Bool) -> Self {
        self.enabled = enabled
        return self
    }
    /// Returns a dictionary with just the enabled flag, if present, or otherwise returns an empty dictionary.
    public func build() -> [String: Any] {
        guard let enabled else {
            return [:]
        }
        return [Self.enabledKey: enabled]
    }
}
