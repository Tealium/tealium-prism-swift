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
    // TODO: rules and mappings
    private var _dataObject = DataObject()
    /// A custom dictionary that holds the configuration for this module.
    /// Do not use this one directly unless you are subclassing this class.
    public var _configurationObject = DataObject()
    public init() { }
    /// Set the enabled flag for these settings.
    public func setEnabled(_ enabled: Bool) -> Self {
        _dataObject.set(enabled, key: ModuleSettings.Keys.enabled)
        return self
    }
    /// Returns the `DataObject` representing the `ModuleSettings` object.
    public func build() -> DataObject {
        _dataObject.set(converting: _configurationObject, key: ModuleSettings.Keys.configuration)
        return _dataObject
    }
}
