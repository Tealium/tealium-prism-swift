//
//  Disposable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol representing a subscription or long-lived operation that can be cancelled.
///
/// **Contract:**
/// - `dispose()` is idempotent — calling it multiple times is safe and has no additional effect.
/// - `isDisposed` returns `true` after `dispose()` has been called.
/// - Implementations are NOT thread-safe unless specifically documented (e.g. `Disposables.composite(queue:)`).
public protocol Disposable: AnyObject {
    /// Whether this disposable has been disposed.
    var isDisposed: Bool { get }
    /// Disposes of this resource. Must be idempotent (safe to call multiple times) in conforming types.
    func dispose()
}

/// A `Disposable` that can hold multiple child `Disposable` instances for bulk disposal.
///
/// When a `CompositeDisposable` is disposed, all of its children are disposed.
public protocol CompositeDisposable: Disposable {
    /// Adds a `Disposable` to this composite.
    ///
    /// If this composite is already disposed, the added disposable is immediately disposed.
    /// If the disposable is already disposed, it is not added.
    ///
    /// - Warning: Make sure both disposables work from the same queue.
    /// For `Tealium` created `Subscribable`s, they will always work from the `TealiumQueue.worker`.
    /// If you want to add another disposable to a Tealium `Disposable`, or add it to another disposable,
    /// make sure you create it like this: `Disposables.composite(for: tealium)`, passing the relative `Tealium` instance.
    ///
    /// - Parameter disposable: The disposable to add.
    /// - Returns: Self after adding the new disposable, to allow chaining.
    @discardableResult
    func add(_ disposable: any Disposable) -> Self

    /// Removes a disposable from this composite using reference identity (`===`).
    /// The removed disposable is NOT disposed — it is only detached from this container.
    ///
    /// - Parameter disposable: The disposable to remove.
    func remove(_ disposable: any Disposable)
}

public extension Disposable {
    /**
     * Add the disposable to a group so that it can be disposed along the others.
     *
     * - Warning: Make sure both disposables work from the same queue.
     * For `Tealium` created `Subscribable`s, they will always work from the `TealiumQueue.worker`.
     * If you want to add another disposable to a Tealium `Disposable`, or add it to another disposable,
     * make sure you create it like this: `Disposables.composite(for: tealium)`, passing the relative `Tealium` instance.
     *
     * - parameter container: The `CompositeDisposable` group that will contain the disposable.
     *
     * - returns: Self after adding it to the container, to allow chaining.
     */
    @discardableResult
    func addTo(_ container: any CompositeDisposable) -> Self {
        container.add(self)
        return self
    }
}

public extension CompositeDisposable {
    /// Adds a block that is called upon disposal of this CompositeDisposable.
    ///
    /// Effectively, this just adds a Subscription to this CompositeDisposable.
    ///
    /// - Warning: Make sure both disposables work from the same queue.
    /// For `Tealium` created `Subscribable`s, they will always work from the `TealiumQueue.worker`.
    /// If you want to add another disposable to a Tealium `Disposable`, or add it to another disposable,
    /// make sure you create it like this: `Disposables.composite(for: tealium)`, passing the relative `Tealium` instance.
    ///
    /// - Parameter block: The block to be called upon disposal.
    /// - Returns: Self after adding the new disposable, to allow chaining.
    @discardableResult
    func onDispose(_ block: @escaping () -> Void) -> Self {
        add(Subscription(onDispose: block))
    }
}
