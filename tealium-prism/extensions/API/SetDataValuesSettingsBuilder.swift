//
//  SetDataValuesSettingsBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if extensions
import TealiumPrismCore
#endif

/// A builder for creating `TransformationSettings` that configure a `SetDataValues` transformer.
///
/// This builder lets you define operations that copy values between paths in the dispatch payload
/// or set constant values at specific destinations.
///
/// Example:
/// ```swift
/// let settings = SetDataValuesSettingsBuilder(id: "my-transform")
///     .setFrom(.key("source"), to: .key("dest"))
///     .setConstant("hello", to: .key("greeting"))
///     .addScope(.afterCollectors)
///     .build()
/// ```
public class SetDataValuesSettingsBuilder: TransformationSettingsBuilder {
    var operations: [SetDataValuesOperation]?

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
    public func setFrom(_ input: ReferenceContainer, to destination: ReferenceContainer) -> Self {
        var ops = operations ?? []
        ops.append(.init(input: .reference(input), destination: destination))
        operations = ops
        return self
    }

    /// Adds an operation that sets a constant value at a location in the dispatch payload.
    /// - Parameters:
    ///   - constant: The constant value to set.
    ///   - destination: A reference to the destination location in the payload.
    /// - Returns: This builder instance for chaining.
    public func setConstant(_ constant: DataInput, to destination: ReferenceContainer) -> Self {
        var ops = operations ?? []
        ops.append(.init(input: .constant(ValueContainer(constant)), destination: destination))
        operations = ops
        return self
    }

    /// Builds a `DataObject` with the configured operations, scopes, and conditions.
    /// Writes whatever properties have been set to the configuration DataObject.
    /// - Returns: A `DataObject` containing only the explicitly configured transformation settings.
    override public func build() -> DataObject {
        typealias Keys = SetDataValuesConfiguration.Keys
        _setConfiguration(DataObject(compacting: [Keys.operations: operations?.map { $0.toDataObject() }]))
        return super.build()
    }
}
