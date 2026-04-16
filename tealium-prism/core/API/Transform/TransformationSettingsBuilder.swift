//
//  TransformationSettingsBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// Base class for building transformation settings as a `DataObject`.
///
/// Concrete subclasses (e.g. `SetDataValuesSettingsBuilder`, `PersistDataValueSettingsBuilder`,
/// `LowerCaseSettingsBuilder`) override ``build()`` to populate transformer-specific configuration
/// and then delegate to `super.build()`.
///
/// Only values that are explicitly set via the builder's methods will appear in the resulting
/// `DataObject`, so programmatic settings won't override remote/local settings for values
/// the caller didn't intend to change.
///
/// Pass the finished builder directly to [`TealiumConfig.setTransformation(_:)`](doc:TealiumConfig/setTransformation(_:))
/// — there is no need to call ``build()`` yourself.
open class TransformationSettingsBuilder {
    typealias Keys = TransformationSettings.Keys
    let id: String
    let transformerId: String
    var scope: TransformationScope?
    var conditions: Rule<Condition>?
    var configuration: DataObject?

    /// Creates a new builder for a transformation with the given unique `id` and `transformerId`.
    /// - Parameters:
    ///   - id: A unique identifier for this transformation instance.
    ///   - transformerId: The identifier of the transformer that will process this configuration.
    public init(id: String, transformerId: String) {
        self.id = id
        self.transformerId = transformerId
    }

    /// Sets the scope in which this transformation should run.
    /// - Parameter scope: The scope to apply.
    /// - Returns: The builder instance for method chaining.
    public func setScope(_ scope: TransformationScope) -> Self {
        self.scope = scope
        return self
    }

    /// Sets the conditions under which this transformation is applied.
    /// - Parameter conditions: A `Rule<Condition>` that must be satisfied for the transformation to run.
    /// - Returns: The builder instance for method chaining.
    public func setConditions(_ conditions: Rule<Condition>) -> Self {
        self.conditions = conditions
        return self
    }

    // Do not use
    @discardableResult
    public func _setConfiguration(_ configuration: DataObject) -> Self {
        if !configuration.keys.isEmpty {
            self.configuration = configuration
        }
        return self
    }

    /// Builds and returns a `DataObject` representing the transformation settings.
    ///
    /// Only explicitly set values are included, so unset properties won't override
    /// other settings sources during merging.
    /// - Returns: A `DataObject` containing only the explicitly configured transformation settings.
    open func build() -> DataObject {
        DataObject(compacting: [
            Keys.id: id,
            Keys.transformerId: transformerId,
            Keys.scope: scope,
            Keys.conditions: conditions,
            Keys.configuration: configuration
        ])
    }
}
