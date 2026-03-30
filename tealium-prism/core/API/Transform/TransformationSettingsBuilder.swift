//
//  TransformationSettingsBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// Base class for building `TransformationSettings`.
///
/// Concrete subclasses (e.g. `SetDataValuesSettingsBuilder`, `PersistDataValueSettingsBuilder`,
/// `LowerCaseSettingsBuilder`) override ``build()`` to populate transformer-specific configuration
/// and then delegate to `super.build()`.
///
/// Pass the finished builder directly to [`TealiumConfig.setTransformation(_:)`](doc:TealiumConfig/setTransformation(_:))
/// — there is no need to call ``build()`` yourself.
open class TransformationSettingsBuilder {
    let id: String
    let transformerId: String
    var conditions: Rule<Condition>?
    var scopes: [TransformationScope] = []
    var configuration: DataObject = [:]

    /// Creates a new builder for a transformation with the given unique `id` and `transformerId`.
    /// - Parameters:
    ///   - id: A unique identifier for this transformation instance.
    ///   - transformerId: The identifier of the transformer that will process this configuration.
    public init(id: String, transformerId: String) {
        self.id = id
        self.transformerId = transformerId
    }

    /// Replaces the current scope list with the given scopes.
    /// - Parameter scopes: The scopes in which this transformation should run.
    /// - Returns: The builder instance for method chaining.
    public func setScopes(_ scopes: [TransformationScope]) -> Self {
        self.scopes = scopes
        return self
    }

    /// Appends a single scope to the current scope list.
    /// - Parameter scope: The scope to add.
    /// - Returns: The builder instance for method chaining.
    public func addScope(_ scope: TransformationScope) -> Self {
        scopes.append(scope)
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
    public func _setConfiguration(_ configuration: DataObject) -> Self {
        self.configuration = configuration
        return self
    }

    /// Builds and returns a `TransformationSettings` from the current builder state.
    /// - Returns: A configured `TransformationSettings` instance.
    open func build() -> TransformationSettings {
        TransformationSettings(id: id,
                               transformerId: transformerId,
                               scopes: scopes,
                               configuration: configuration,
                               conditions: conditions)
    }

}
