//
//  Transformer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 29/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// An object that will apply different transformations, selected by `transformationId`, to a dispatch.
public protocol Transformer: Module {
    /// Applies the specified `transformation` to a `Dispatch` for the `DispatchScope`
    /// in which this transformation is called.
    ///
    /// - Threading: This method is called on the Tealium queue, and the caller disposes the returned
    ///   `Disposable` on the Tealium queue. `completion` must be called on the Tealium queue (see
    ///   ``TealiumContext/queue``); it may be called synchronously, before this method returns.
    /// - Completion: Call `completion` exactly once, unless the caller has disposed the returned
    ///   `Disposable`. Pass the transformed or unchanged dispatch for it to proceed, or `nil` to drop
    ///   it and stop any further processing.
    /// - Cancellation: The caller may dispose the returned `Disposable` to cancel the transformation.
    ///   After that, calling `completion` is not required, and the caller ignores any call. Disposing
    ///   after `completion` has been called must have no effect. Implementations with nothing to
    ///   cancel, including synchronous ones, return `Disposables.disposed()`.
    /// - Returns: A `Disposable` that cancels in-progress work, or `Disposables.disposed()` if there is
    ///   nothing to cancel.
    @discardableResult
    func applyTransformation(_ transformation: TransformationSettings,
                             to dispatch: Dispatch,
                             scope: DispatchScope,
                             completion: @escaping (Dispatch?) -> Void) -> any Disposable
}

/**
 * The `TransformerRegistrar` is responsible for registering and unregistering additional
 * `TransformationSettings`s outside of those provided by the main SDK settings.
 */
public protocol TransformerRegistrar {
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
