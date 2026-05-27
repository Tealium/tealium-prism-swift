//
//  Observable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// An abstract base class for observable sequences.
///
/// Subclasses must override `subscribe(_:)` to provide the subscription behavior.
/// For a callback-style observable, use `Observables.create` and provide a `SubscriptionHandler`.
///
/// **Completion contract:** After `onComplete()` is forwarded to a downstream observer,
/// no further `onNext` events will be delivered through that subscription.
/// The subscription is considered terminated and its resources are released.
///
/// - Warning: This class is not generically Thread safe.
/// Usage, including operators, subscription and emission of events, must be done from a single queue.
/// When the source emits on a different queue than the caller, use `subscribeOn` immediately before subscribing,
/// to ensure subscription happens on the source's queue.
public class Observable<Element>: Subscribable, ObservableConvertible {
    /// A handler called upon subscription to an observable with the given observer.
    public typealias SubscriptionHandler = (any Observer<Element>) -> any Disposable

    init() {}

    /// Subscribes an `Observer` to receive elements and completion.
    /// - Returns: A `Disposable` representing the subscription. Disposing it cancels event delivery
    ///   (the observer will no longer receive `onNext` or `onComplete`).
    @discardableResult
    public func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        fatalError("Observable.subscribe(_:) must be overridden by subclasses")
    }
}

public extension Observable {
    /**
     * Subscribes the observer only once and then automatically disposes it.
     *
     * This is meant to be used when you only need one observer to be registered once.
     * Use the standalone `first()` operator if multiple observers all need to register for one event.
     *
     * - Warning: This method must be called from the thread on which the `Observable` emits events.
     * Calling from a different thread can cause race conditions and crashes.
     *
     * - returns: a `Disposable` that can be used to dispose this observer before the first event is sent to the observer, in case it's not needed any longer.
     */
    @discardableResult
    func subscribeOnce(_ observer: @escaping (Element) -> Void) -> any Disposable {
        first().subscribe(observer)
    }

    /**
     * Subscribes the given `observer` to receive updates, including an `Observer.onComplete`
     * notification when the upstream source terminates. The subscription is stored in the given `composite`.
     *
     * Upon the `Observer.onComplete` signal, the `observer` is removed from the given `composite`.
     *
     * - Warning: adding to the `composite` happens on the caller thread, and removals may happen on a different
     * one. As such, users should be certain that either `composite` is thread-safe, or that the caller
     * and disposal thread are the same.
     *
     * - Parameters:
     *  - composite: The `CompositeDisposable` that will store the returned `Disposable` until the `Observer` completes.
     *  - observer: The `Observer` to receive values and the completion signal.
     * - returns: A `Disposable` for cancelling the subscription. Can be ignored as it will be stored in the composite until completed.
     */
    @discardableResult
    func subscribe(composite: any CompositeDisposable, observer: any Observer<Element>) -> any Disposable {
        let obs = UnsubscribingObserver(owner: composite, delegate: observer)
        let upstream = subscribe(obs)
        obs.setUpstream(upstream)
        composite.add(obs)
        return obs
    }
}
