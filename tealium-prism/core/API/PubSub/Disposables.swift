//
//  Disposables.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 08/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Contains factory methods for creating common `Disposable` instances for use with the Tealium SDK.
 */
public enum Disposables {
}

public extension Disposables {
    /**
     * Creates a `Disposable` which calls the given `unsubscribe` block when the subscription is disposed.
     *
     * The returned implementation is not considered  to be thread-safe, so interaction is expected
     * to be constrained to an appropriate thread by the user.
     *
     * - parameter unsubscribe: Optional callback to execute when this `Disposable` is disposed.
     *
     * - returns: A `Disposable` to dispose of the subscription.
     */
    static func subscription(unsubscribe: @escaping () -> Void = { }) -> Disposable {
        Subscription(unsubscribe: unsubscribe)
    }

    /**
     * Creates a `CompositeDisposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     *
     * Additional `Disposable` instances can be added via `CompositeDisposable.add`.
     *
     * The returned implementation is not considered to be thread-safe, so interaction is expected
     * to be constrained to an appropriate thread by the user.
     *
     * - returns: A `CompositeDisposable` to dispose of multiple `Disposable` at once.
     */
    static func composite() -> CompositeDisposable {
        DisposableContainer()
    }

    /**
     * Creates a `CompositeDisposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     * All methods are executed using the given `queue` to ensure operation is thread-safe.
     *
     * Additional `Disposable` instances can be added via `CompositeDisposable.add`.
     *
     *
     * - parameter queue: The `TealiumQueue` implementation to use for all operations of this `Disposable`.
     *
     * - returns: A `CompositeDisposable` to dispose of multiple `Disposable` at once, whilst ensuring that all operations
     * happen on the given `queue`.
     */
    static func composite(queue: TealiumQueue) -> CompositeDisposable {
        AsyncDisposableContainer(queue: queue)
    }

    /**
     * Creates a `CompositeDisposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     * This `Disposable` will automatically dispose upon deinitialization.
     *
     * Additional `Disposable` instances can be added via `CompositeDisposable.add`.
     *
     * The returned implementation is not considered to be thread-safe, so interaction is expected
     * to be constrained to an appropriate thread by the user.
     *
     * - returns: A `CompositeDisposable` to dispose of multiple `Disposable` at once.
     */
    static func automaticComposite() -> CompositeDisposable {
        AutomaticDisposer()
    }

    /**
     * Returns a `Disposable` implementation that:
     *  - always returns `true` for `Disposable.isDisposed`
     *  - does nothing for `Disposable.dispose`
     *
     *  - returns A disposed `Disposable`
     */
    static func disposed() -> Disposable {
        Subscription.completed
    }
}
