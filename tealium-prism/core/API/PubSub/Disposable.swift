//
//  Disposable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol representing some long-lived operation (or operations) that can be disposed.
public protocol Disposable {
    /// Whether this disposable has been disposed.
    var isDisposed: Bool { get }
    /// Disposes of this resource.
    func dispose()

    /// Adds a Disposable to this Disposable.
    ///
    /// - Warning: Make sure both disposables work from the same queue.
    /// For `Tealium` created `Subscribable`s, they will always work from the `TealiumQueue.worker`.
    /// If you want to add another disposable to a Tealium `Disposable`, or add it to another disposable,
    /// make sure you create it like this: `Disposables.composite(for: tealium)`, passing the relative `Tealium` instance.
    ///
    /// - Parameter disposable: The disposable to add.
    /// - Returns: Self after adding the new disposable, to allow chaining.
    @discardableResult
    func add(_ disposable: Disposable) -> Self
}

public extension Disposable {
    /**
     * Add the disposable to a group so that it can be disposed along the others.
     *
     * - Warning: Make sure both disposables work from the same queue.
     * For `Tealium` created `Subscribable`s, they will always work from the `TealiumQueue.worker`.
     * If you want to add another disposable to a Tealium `Disposable`, or add it to another disposable,
     /// make sure you create it like this: `Disposables.composite(for: tealium)`, passing the relative `Tealium` instance.
     *
     * - parameter container: The `Disposable` group that will contain the disposable.
     *
     * - returns: Self after adding it to the container, to allow chaining.
     */
    @discardableResult
    func addTo(_ container: Disposable) -> Self {
        container.add(self)
        return self
    }

    /// Adds a block that is called upon disposal of this Disposable.
    ///
    /// Effectively, this just adds a Subscription to this Disposable.
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
