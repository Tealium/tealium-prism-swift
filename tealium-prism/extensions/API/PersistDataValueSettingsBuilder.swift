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

public class PersistDataValueSettingsBuilder: TransformationSettingsBuilder {
    var input: ValueSource?
    var destination: ReferenceContainer?
    var expiry: Expiry = .session
    var updateBehavior: UpdateBehavior = .allowUpdate

    public init(id: String) {
        super.init(id: id, transformerId: Modules.Types.persistDataValueTransformer)
    }

    /**
     * Configures the transformation to persist a constant value to a specified destination of the data layer.
     *
     * This method sets up the transformation to store a fixed value
     * at the specified destination path in the data layer. The value will be persisted
     * according to the configured expiry and update behavior settings.
     *
     * - Parameters:
     *   - input: The constant value to be persisted.
     *   - destination: A `ReferenceContainer` specifying where in the data layer to store the value.
     *                  Can be a simple key or a nested path.
     *
     * - Returns: The builder instance for method chaining.
     */
    public func persist(
        input: String,
        destination: ReferenceContainer
    ) -> Self {
        self.input = .constant(ValueContainer(input))
        self.destination = destination
        return self
    }

    /**
     * Configures the transformation to persist a value from the `Dispatch` payload to a specified destination of the data layer.
     *
     * This method sets up the transformation to copy a value from an existing location in the
     * payload (specified by the input `ReferenceContainer`) to the specified destination path in the data layer.
     * The value will be persisted according to the configured expiry and update behavior settings.
     *
     * - Parameters:
     *   - input: A `ReferenceContainer` specifying the source location in the 'Dispatch' payload
     *            from which to read the value to be persisted.
     *   - destination: A `ReferenceContainer` specifying where in the data layer to store the value.
     *                  Can be a simple key or a nested path.
     *
     * - Returns: The builder instance for method chaining.
     */
    public func persist(
        input: ReferenceContainer,
        destination: ReferenceContainer
    ) -> Self {
        self.input = .reference(input)
        self.destination = destination
        return self
    }

    /**
     * Sets the expiry policy for the persisted data.
     *
     * This method configures how long the persisted value should remain in the data store
     * before it expires and is automatically removed. The expiry policy determines the
     * lifecycle of the stored data.
     *
     * - Parameter expiry: The `Expiry` policy to apply to the persisted data.
     *                     Common values include `.session` (expires when the session ends),
     *                     `.forever` (never expires), or custom time-based expiry.
     *
     * - Returns: The builder instance for method chaining.
     */
    public func setExpiry(_ expiry: Expiry) -> Self {
        self.expiry = expiry
        return self
    }

    /**
     * Sets the update behavior for the persisted data.
     *
     * This method configures how the transformation should behave when attempting to persist
     * data to a destination that already contains a value. The update behavior determines
     * whether existing values can be overwritten or should be preserved.
     *
     * - Parameter updateBehavior: The `UpdateBehavior` policy to apply when the destination
     *                             already contains data. Use `.allowUpdate` to overwrite
     *                             existing values, or `.keepFirstValue` to preserve existing
     *                             values and skip the persistence operation.
     *
     * - Returns: The builder instance for method chaining.
     */
    public func setUpdateBehavior(_ updateBehavior: UpdateBehavior) -> Self {
        self.updateBehavior = updateBehavior
        return self
    }

    override public func build() -> TransformationSettings {
        if let input = self.input, let destination = self.destination {
            let config = PersistDataValueConfiguration(
                destination: destination,
                input: input,
                expiry: expiry,
                updateBehavior: updateBehavior
            )
            _ = _setConfiguration(config.toDataObject())
        }
        return super.build()
    }
}
