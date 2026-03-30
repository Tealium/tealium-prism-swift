//
//  PersistDataValueSettingsBuilder.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if extensions
import TealiumPrismCore
#endif

/// Defines how a persisted value should behave when a value already exists at the destination.
/// Use this to control whether a new value can overwrite an existing one.
public enum UpdatePolicy: String, Equatable {
    /// Subsequent persist operations are allowed to overwrite any existing value
    /// at the destination with the latest value.
    case allowUpdate
    /// The first successfully persisted value is kept; any later attempts to
    /// persist a new value to the same destination are ignored.
    case keepFirstValue

    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case Self.allowUpdate.rawValue.lowercased():
            self = .allowUpdate
        case Self.keepFirstValue.rawValue.lowercased():
            self = .keepFirstValue
        default:
            return nil
        }
    }
}

/// Builder for creating a `PersistDataValue` transformation that stores a value from the dispatch payload
/// (or a constant) into the data layer with a configurable expiry and update policy.
///
/// Example usage:
/// ```swift
/// let settings = PersistDataValueSettingsBuilder(id: "persist-user-id")
///     .persist(input: .key("user_id"), destination: .key("persisted_user_id"))
///     .setExpiryPolicy(.forever)
///     .setUpdatePolicy(.keepFirstValue)
///     .addScope(.afterCollectors)
///     .build()
/// ```
public class PersistDataValueSettingsBuilder: TransformationSettingsBuilder {
    var input: ValueSource?
    var destination: ReferenceContainer?
    var expiryPolicy: ExpiryPolicy?
    var updatePolicy: UpdatePolicy?

    /// Creates a new builder for a `PersistDataValue` transformation with the given unique `id`.
    /// - Parameter id: A unique identifier for this transformation instance.
    public init(id: String) {
        super.init(id: id, transformerId: Modules.Types.persistDataValueTransformer)
    }

    /// Configures the transformation to persist a constant value to a specified destination of the data layer.
    ///
    /// This method sets up the transformation to store a fixed value
    /// at the specified destination path in the data layer. The value will be persisted
    /// according to the configured expiry and update policy settings. If not specified,
    /// defaults to `.session` expiry and `.allowUpdate` policy.
    ///
    /// - Parameters:
    ///   - input: The constant value to be persisted.
    ///   - destination: A `ReferenceContainer` specifying where in the data layer to store the value.
    ///                  Can be a simple key or a nested path.
    /// - Returns: The builder instance for method chaining.
    public func persist(
        input: String,
        destination: ReferenceContainer
    ) -> Self {
        self.input = .constant(ValueContainer(input))
        self.destination = destination
        return self
    }

    /// Configures the transformation to persist a value from the `Dispatch` payload to a specified destination of the data layer.
    ///
    /// This method sets up the transformation to copy a value from an existing location in the
    /// payload (specified by the input `ReferenceContainer`) to the specified destination path in the data layer.
    /// The value will be persisted according to the configured expiry and update policy settings.
    /// If not specified, defaults to `.session` expiry and `.allowUpdate` policy.
    ///
    /// - Parameters:
    ///   - input: A `ReferenceContainer` specifying the source location in the 'Dispatch' payload
    ///            from which to read the value to be persisted.
    ///   - destination: A `ReferenceContainer` specifying where in the data layer to store the value.
    ///                  Can be a simple key or a nested path.
    /// - Returns: The builder instance for method chaining.
    public func persist(
        input: ReferenceContainer,
        destination: ReferenceContainer
    ) -> Self {
        self.input = .reference(input)
        self.destination = destination
        return self
    }

    /// Sets the expiry policy for the persisted data.
    ///
    /// This method configures how long the persisted value should remain in the data store
    /// before it expires and is automatically removed. The expiry policy determines the
    /// lifecycle of the stored data.
    ///
    /// If not called, the default expiry policy of `.session` will be used.
    ///
    /// - Parameter expiryPolicy: The `ExpiryPolicy` to apply to the persisted data.
    ///                           Common values include `.session` (expires when the session ends),
    ///                           `.forever` (never expires), or `.duration(timeFrame)` for
    ///                           custom time-based expiry.
    /// - Returns: The builder instance for method chaining.
    public func setExpiryPolicy(_ expiryPolicy: ExpiryPolicy) -> Self {
        self.expiryPolicy = expiryPolicy
        return self
    }

    /// Sets the update policy for the persisted data.
    ///
    /// This method configures how the transformation should behave when attempting to persist
    /// data to a destination that already contains a value. The update policy determines
    /// whether existing values can be overwritten or should be preserved.
    ///
    /// If not called, the default update policy of `.allowUpdate` will be used.
    ///
    /// - Parameter updatePolicy: The `UpdatePolicy` policy to apply when the destination
    ///                             already contains data. Use `.allowUpdate` to overwrite
    ///                             existing values, or `.keepFirstValue` to preserve existing
    ///                             values and skip the persistence operation.
    /// - Returns: The builder instance for method chaining.
    public func setUpdatePolicy(_ updatePolicy: UpdatePolicy) -> Self {
        self.updatePolicy = updatePolicy
        return self
    }

    /// Builds the `TransformationSettings` from the current builder state.
    /// Writes whatever properties have been set to the configuration DataObject.
    override public func build() -> TransformationSettings {
        typealias ConfigKeys = PersistDataValueConfiguration.Keys
        _ = _setConfiguration([
            ConfigKeys.input: input,
            ConfigKeys.destination: destination,
            ConfigKeys.duration: expiryPolicy,
            ConfigKeys.updatePolicy: updatePolicy?.rawValue,
        ])
        return super.build()
    }
}
