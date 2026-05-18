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
     * Creates a NON Thread Safe `CompositeDisposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     *
     * Additional `Disposable` instances can be added via `CompositeDisposable.add`.
     *
     * The returned implementation is not considered to be thread-safe, so interaction is expected
     * to be constrained to an appropriate thread by the user.
     *
     * - returns: A `CompositeDisposable` to dispose of multiple `Disposable` at once.
     */
    static func composite() -> any CompositeDisposable {
        DisposableContainer()
    }

    /**
     * Creates a NON Thread Safe `Disposable` which calls the given `onDispose` block when disposed.
     *
     * The returned implementation is not considered to be thread-safe, so interaction is expected
     * to be constrained to an appropriate thread by the user.
     *
     * - parameter onDispose: Callback to execute when this `Disposable` is disposed.
     *
     * - returns: A `Disposable` that calls the `onDispose` block upon disposal.
     */
    static func subscription(onDispose: @escaping () -> Void) -> any Disposable {
        Subscription(onDispose: onDispose)
    }

    /**
     * Creates a `CompositeDisposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     * All methods are executed using the given `queue` to ensure operation is thread-safe.
     *
     * Additional `Disposable` instances can be added via `CompositeDisposable.add`.
     *
     * - parameter queue: The `TealiumQueue` instance to use for all operations of this `CompositeDisposable`. Must be the same
     * one used from the operations that can be disposed by this `CompositeDisposable`.
     *
     * - returns: A `CompositeDisposable` to dispose some operations, whilst ensuring that all operations happen on the given `queue`.
     */
    static func composite(queue: TealiumQueue) -> any CompositeDisposable {
        AsyncDisposableContainer(queue: queue)
    }

    /**
     * Creates a `CompositeDisposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     * All methods are executed using the internal `Tealium` queue to ensure operation is thread-safe when containing
     * `Tealium` returned subscriptions.
     *
     * Additional `Disposable` instances can be added via `CompositeDisposable.add`.
     *
     * - returns: A `CompositeDisposable` to dispose some operations, whilst ensuring that all operations happen on the `Tealium` internal queue.
     */
    static func composite(for tealium: Tealium) -> any CompositeDisposable {
        tealium.createDisposable()
    }

    /**
     * Creates a NON Thread Safe `CompositeDisposable` which can be used to store multiple `Disposable` instances for bulk disposal.
     * This `CompositeDisposable` will automatically dispose upon deinitialization.
     *
     * Additional `Disposable` instances can be added via `CompositeDisposable.add`.
     *
     * The returned implementation is not considered to be thread-safe, so interaction is expected
     * to be constrained to an appropriate thread by the user.
     *
     * - returns: A `CompositeDisposable` to dispose of multiple `Disposable` at once.
     */
    static func automatic() -> any CompositeDisposable {
        AutomaticDisposer()
    }

    /**
     * Returns a `Disposable` implementation that:
     *  - always returns `true` for `Disposable.isDisposed`
     *  - does nothing for `Disposable.dispose`
     *
     *  - returns A disposed `Disposable`
     */
    static func disposed() -> any Disposable {
        CompletedDisposable.shared
    }
}
