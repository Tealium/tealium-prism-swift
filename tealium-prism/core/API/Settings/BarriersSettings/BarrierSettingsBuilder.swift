//
//  BarrierSettingsBuilder.swift
//  tealium-prism
//
//  Created by Den Guzov on 09/12/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder class for configuring barrier settings.
open class BarrierSettingsBuilder {
    typealias Keys = BarrierSettings.Keys
    private var _dataObject = DataObject()

    /// A custom dictionary that holds the configuration for this barrier.
    /// Do not use this one directly unless you are subclassing this class.
    public var _configurationObject = DataObject()

    /// Creates a new barrier settings builder.
    public init() { }

    /// Set the scopes where this barrier should be applied.
    /// - Parameter scopes: An array of `BarrierScope` values defining where the barrier applies.
    /// - Returns: The builder instance for method chaining.
    public func setScopes(_ scopes: [BarrierScope]) -> Self {
        _dataObject.set(converting: scopes, key: Keys.scopes)
        return self
    }

    /// - Returns: the `DataObject` representing the `BarrierSettings` object.
    public func build() -> DataObject {
        _dataObject.set(converting: _configurationObject, key: Keys.configuration)
        return _dataObject
    }
}
