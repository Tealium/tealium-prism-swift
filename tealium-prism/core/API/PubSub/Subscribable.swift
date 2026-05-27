//
//  Subscribable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A type that can be converted to an `Observable`.
public protocol ObservableConvertible<Element> {
    /// The type of element emitted by this observable source.
    associatedtype Element

    /// Convert the current object to an `Observable`.
    func asObservable() -> Observable<Element>
}

/// A type that can be subscribed to by an `Observer` to receive elements and completion.
public protocol Subscribable<Element> {
    associatedtype Element
    /// Subscribes an `Observer` to receive elements and completion.
    /// - Returns: A `Disposable` representing the subscription. Disposing it stops event delivery.
    @discardableResult
    func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable
}

public extension Subscribable {

    /**
     * Subscribe a callback to receive the `Element`.
     *
     * - parameter onNext: The callback called with the `Element`.
     * - parameter onComplete: The callback called once when the upstream source completes. Not invoked on external disposal.
     * - returns: A `Disposable` that can be disposed to stop the observer from being called.
     */
    @discardableResult
    func subscribe(_ onNext: @escaping (Element) -> Void, onComplete: @escaping () -> Void = { }) -> any Disposable {
        let observer = ThreadSafeAnonymousObserver(onNext: onNext, onComplete: onComplete)
        let upstream = self.subscribe(observer)
        observer.setUpstream(upstream)
        return observer
    }
}

public extension ObservableConvertible where Self: Subscribable {
    func asObservable() -> Observable<Element> {
        Observables.create { observer in self.subscribe(observer) }
    }
}
