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
 *
 * Disposable implementations are not Thread safe. An application that wants to dispose of multiple Tealium's `Disposable`s at the same time,
 * should only use `Disposables.composite(for: tealium)` instances, passing a `Tealium` instance as a parameter.
 *
 * ```swift
    let sharedDisposable = Disposables.composite(for: tealium)

    func subscribeToDataLayerChanges() {
       tealium.dataLayer.onDataUpdated.subscribe { updated in
           print("New dataLayer update: \(updated)")
       }.addTo(sharedDisposable)

       tealium.dataLayer.onDataRemoved.subscribe { removed in
           print("Data removed for keys \(removed)")
       }.addTo(sharedDisposable)
    }

    // Later, when changes events are no longer needed
    sharedDisposable.dispose()
 * ```
 */
public enum Disposables {
}

public extension Disposables {

    /**
     * Creates a NON Thread Safe `Disposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     *
     * Additional `Disposable` instances can be added via `Disposable.add`.
     *
     * The returned implementation is not considered to be thread-safe, so interaction is expected
     * to be constrained to an appropriate thread by the user.
     *
     * - returns: A `Disposable` to dispose of multiple `Disposable` at once.
     */
    static func composite() -> Disposable {
        DisposableContainer()
    }

    /**
     * Creates a NON Thread Safe `Disposable` which calls the given `onDispose` block when disposed.
     *
     * Additional `Disposable` instances can be added via `Disposable.add`.
     *
     * The returned implementation is not considered to be thread-safe, so interaction is expected
     * to be constrained to an appropriate thread by the user.
     *
     * - parameter onDispose: Callback to execute when this `Disposable` is disposed.
     *
     * - returns: A `Disposable` to dispose of the subscription.
     */
    static func composite(onDispose: @escaping () -> Void) -> Disposable {
        Subscription(onDispose: onDispose)
    }

    /**
     * Creates a `Disposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     * All methods are executed using the given `queue` to ensure operation is thread-safe.
     *
     * Additional `Disposable` instances can be added via `Disposable.add`.
     *
     * - parameter queue: The `TealiumQueue` instance to use for all operations of this `Disposable`. Must be the same
     * one used from the operations that can be disposed by this `Disposable`.
     *
     * - returns: A `Disposable` to dispose some operations, whilst ensuring that all operations happen on the given `queue`.
     */
    static func composite(queue: TealiumQueue) -> Disposable {
        AsyncDisposableContainer(queue: queue)
    }

    /**
     * Creates a `Disposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     * All methods are executed using the internal `Tealium` queue to ensure operation is thread-safe when containing
     * `Tealium` returned subscriptions.
     *
     * Additional `Disposable` instances can be added via `Disposable.add`.
     *
     * - returns: A `Disposable` to dispose some operations, whilst ensuring that all operations happen on the `Tealium` internal queue.
     */
    static func composite(for tealium: Tealium) -> Disposable {
        tealium.createDisposable()
    }

    /**
     * Creates a NON Thread Safe `Disposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     * This `Disposable` will automatically dispose upon deinitialization.
     *
     * Additional `Disposable` instances can be added via `Disposable.add`.
     *
     * The returned implementation is not considered to be thread-safe, so interaction is expected
     * to be constrained to an appropriate thread by the user.
     *
     * - returns: A `Disposable` to dispose of multiple `Disposable` at once.
     */
    static func automatic() -> Disposable {
        AutomaticDisposer()
    }

    /**
     * Returns a `Disposable` implementation that:
     *  - always returns `true` for `Disposable.isDisposed`
     *  - does nothing for `Disposable.dispose`
     *  - immediately disposes additional `Disposable` added to it.
     *
     *  - returns A disposed `Disposable`
     */
    static func disposed() -> Disposable {
        CompletedDisposable.shared
    }
}
