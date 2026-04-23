//
//  Observable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// An abstract class that allows to subscribe for events until the returned subscription is disposed.
///
/// Subclasses must override `subscribe(_:)` to provide the subscription behavior.
/// For a callback-style observable, use `Observables.create` and provide a `SubscriptionHandler`.
public class Observable<Element>: Subscribable {
    /// A handler called upon subscription to an observable with the given observer.
    public typealias SubscriptionHandler = (any Observer<Element>) -> Disposable

    init() {}

    /// Subscribes an `Observer` to receive elements and completion.
    /// Must be overridden by subclasses.
    @discardableResult
    public func subscribe<O: Observer<Element>>(_ observer: O) -> Disposable {
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
     * - returns: a `Disposable` that can be used to dispose this observer before the first event is sent to the observer, in case it's not needed any longer.
     */
    @discardableResult
    func subscribeOnce(_ observer: @escaping (Element) -> Void) -> Disposable {
        first().subscribe(observer)
    }
}
