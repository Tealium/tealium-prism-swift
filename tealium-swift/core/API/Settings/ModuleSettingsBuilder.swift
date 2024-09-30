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
    /// A custom dictionary that holds the settings for this builder.
    /// Do not use this directly unless you are subclassing this class.
    public var _dataObject = DataObject()
    public init() { }
    /// Set the enabled flag for these settings.
    public func setEnabled(_ enabled: Bool) -> Self {
        _dataObject.set(enabled, key: Self.enabledKey)
        return self
    }
    /// Returns a dictionary with just the enabled flag, if present, or otherwise returns an empty dictionary.
    public func build() -> DataObject {
        _dataObject
    }
}
