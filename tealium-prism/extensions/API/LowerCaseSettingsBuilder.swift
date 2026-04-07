//
//  LowerCaseSettingsBuilder.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

#if extensions
import TealiumPrismCore
#endif

/// A builder for creating `TransformationSettings` that configure a `LowerCase` transformer.
///
/// This builder lets you lowercase all string values in the dispatch payload, or target
/// specific keys for lowercasing. An empty/non-present configuration will effectively
/// enable the default behavior: lowercase all string values.
///
/// String values inside arrays and dictionaries are lowercased recursively. Non-string values
/// (e.g. numbers, booleans) are preserved as-is. The visitor ID (`tealium_visitor_id`) is
/// always preserved unchanged, even when lowercasing all variables, unless the user intentionally
/// configures this transformation to be applied to the visitor ID.
///
/// Example:
/// ```swift
/// // Lowercase everything (default)
/// let settings = LowerCaseSettingsBuilder(id: "my-lower")
///     .build()
///
/// // Lowercase only specific keys
/// let settings = LowerCaseSettingsBuilder(id: "my-lower")
///     .setAllVariables(false)
///     .addVariable(.key("user_name"))
///     .addVariable(.key("email"))
///     .build()
/// ```
public class LowerCaseSettingsBuilder: TransformationSettingsBuilder {
    var allVariables: Bool?
    var inputs: [ReferenceContainer] = []

    /// Creates a new builder for a LowerCase transformation.
    /// - Parameter id: A unique identifier for this transformation.
    public init(id: String) {
        super.init(id: id, transformerId: Modules.Types.lowerCaseTransformer)
    }

    /// Sets whether to lowercase all string variables in the payload.
    /// - Parameter all: `true` to lowercase all strings (default), `false` to use only the operations added via `addVariable(_:)`.
    /// - Returns: This builder instance for chaining.
    public func setAllVariables(_ all: Bool) -> Self {
        self.allVariables = all
        return self
    }

    /// Adds a variable to be lowercased in place.
    /// - Parameter reference: A reference to the key in the payload to lowercase.
    /// - Returns: This builder instance for chaining.
    public func addVariable(_ reference: ReferenceContainer) -> Self {
        inputs.append(reference)
        return self
    }

    /// Builds the `TransformationSettings` with the configured operations, scopes, and conditions.
    /// - Returns: A `TransformationSettings` instance ready to be applied by the transformer.
    override public func build() -> TransformationSettings {
        typealias Keys = LowerCaseConfiguration.Keys
        _ = _setConfiguration(DataObject(compacting: [
            Keys.inputs: inputs.map { $0.toDataObject() },
            Keys.allVariables: allVariables
        ]))
        return super.build()
    }
}
