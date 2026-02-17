//
//  SetDataValuesSettingsBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if extensions
import TealiumPrismCore
#endif

/// A builder for creating ``TransformationSettings`` that configure a `SetDataValues` transformer.
///
/// This builder lets you define operations that copy values between paths in the dispatch payload
/// or set constant values at specific destinations.
///
/// Example:
/// ```swift
/// let settings = SetDataValuesSettingsBuilder(id: "my-transform")
///     .addOperation(input: .key("source"), destination: .key("dest"))
///     .addOperation(input: ValueContainer("hello"), destination: .key("greeting"))
///     .addScope(.afterCollectors)
///     .build()
/// ```
public class SetDataValuesSettingsBuilder: TransformationSettingsBuilder {
    var operations: [TransformationOperation<SetDataValuesParameters>] = []

    /// Creates a new builder for a SetDataValues transformation.
    /// - Parameter id: A unique identifier for this transformation.
    public init(id: String) {
        super.init(id: id, transformerId: Modules.Types.setDataValuesTransformer)
    }

    /// Adds an operation that copies a value from one location to another in the dispatch payload.
    /// - Parameters:
    ///   - input: A reference to the source location in the payload.
    ///   - destination: A reference to the destination location in the payload.
    /// - Returns: This builder instance for chaining.
    public func addOperation(input: ReferenceContainer, destination: ReferenceContainer) -> Self {
        operations.append(.init(destination: destination, parameters: .init(input: .reference(input))))
        return self
    }

    /// Adds an operation that sets a constant value at a location in the dispatch payload.
    /// - Parameters:
    ///   - input: The constant value to set.
    ///   - destination: A reference to the destination location in the payload.
    /// - Returns: This builder instance for chaining.
    public func addOperation(input: ValueContainer, destination: ReferenceContainer) -> Self {
        operations.append(.init(destination: destination, parameters: .init(input: .constant(input))))
        return self
    }

    /// Builds the ``TransformationSettings`` with the configured operations, scopes, and conditions.
    /// - Returns: A ``TransformationSettings`` instance ready to be applied by the transformer.
    override public func build() -> TransformationSettings {
        _ = _setConfiguration(SetDataValuesConfiguration(operations: operations)
            .toDataObject())
        return super.build()
    }
}
