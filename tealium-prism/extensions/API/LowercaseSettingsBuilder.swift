//
//  LowercaseSettingsBuilder.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

#if extensions
import TealiumPrismCore
#endif

/// A builder for creating `TransformationSettings` that configure a `Lowercase` transformer.
///
/// Use ``lowercaseAllVariables()`` to lowercase every string value in the dispatch payload, or
/// ``lowercaseVariables(_:)`` to target specific keys. When neither method is called the transformation
/// is a no-op (the dispatch passes through unchanged).
///
/// **All-variables mode** — string values inside arrays and nested dictionaries are lowercased
/// recursively. Non-string values (e.g. numbers, booleans) are preserved as-is. The visitor ID
/// (`tealium_visitor_id`), CP trace ID (`cp.trace_id`), and Tealium trace ID (`tealium_trace_id`)
/// are always preserved, unless they are explicitly listed via ``lowercaseVariables(_:)``.
///
/// **Specific-variables mode** — only the values at the specified paths are lowercased.
/// String values are lowercased directly; arrays and dictionaries are descended recursively and
/// their string elements are lowercased. Non-string scalar values (e.g. numbers, booleans) are
/// left unchanged. The excluded keys above are **not** automatically protected; listing them in
/// ``lowercaseVariables(_:)`` will lowercase them.
///
/// Example:
/// ```swift
/// // Lowercase everything
/// let settings = LowercaseSettingsBuilder(id: "my-lower")
///     .lowercaseAllVariables()
///     .build()
///
/// // Lowercase only specific keys
/// let settings = LowercaseSettingsBuilder(id: "my-lower")
///     .lowercaseVariables([.key("user_name"), .key("email")])
///     .build()
/// ```
public class LowercaseSettingsBuilder: TransformationSettingsBuilder {
    var policy: LowercasePolicy?

    /// Creates a new builder for a Lowercase transformation.
    /// - Parameter id: A unique identifier for this transformation.
    public init(id: String) {
        super.init(id: id, transformerId: Modules.Types.lowercaseTransformer)
    }

    /// Configures the transformation to lowercase all string variables in the payload.
    /// - Returns: This builder instance for chaining.
    @discardableResult
    public func lowercaseAllVariables() -> Self {
        self.policy = .allVariables
        return self
    }

    /// Configures the transformation to lowercase only the specified variables.
    ///
    /// String values are lowercased directly; arrays and dictionaries are descended recursively and
    /// their string elements are lowercased. Non-string scalar values (numbers, booleans) are left unchanged.
    /// - Parameter variables: The list of references to keys in the payload to lowercase.
    /// - Returns: This builder instance for chaining.
    @discardableResult
    public func lowercaseVariables(_ variables: [ReferenceContainer]) -> Self {
        self.policy = .variables(variables)
        return self
    }

    /// Builds a `DataObject` with the configured operations, scope, and conditions.
    /// - Returns: A `DataObject` containing only the explicitly configured transformation settings.
    override public func build() -> DataObject {
        _setConfiguration(DataObject(compacting: [
            LowercaseConfiguration.Keys.variables: policy
        ]))
        return super.build()
    }
}
