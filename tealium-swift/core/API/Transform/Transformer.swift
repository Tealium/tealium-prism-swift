//
//  Transformer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 29/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// An object that will apply different transformations, selected by `transformationId`, to a dispatch.
public protocol Transformer: Module {
    /// Applies a transformation, identified by a `transformationId`, to a `Dispatch` for the `DispatchScope` in which this transformation is called.
    func applyTransformation(_ transformation: TransformationSettings,
                             to dispatch: Dispatch,
                             scope: DispatchScope,
                             completion: @escaping (Dispatch?) -> Void)
}

/**
 * The `TransformerRegistry` is responsible for registering and unregistering additional
 * `TransformationSettings`s outside of those provided by the main SDK settings.
 */
public protocol TransformerRegistry {
    /**
     * Registers an additional `TransformationSettings`.
     *
     * - parameter transformation: The `TransformationSettings` to add to the current set of transformations
     */
    func registerTransformation(_ transformation: TransformationSettings)

    /**
     * Unregisters the given `transformation` if it is currently registered
     *
     * - parameter transformation The `TransformationSettings` to remove from the current set of transformations
     */
    func unregisterTransformation(_ transformation: TransformationSettings)
}
