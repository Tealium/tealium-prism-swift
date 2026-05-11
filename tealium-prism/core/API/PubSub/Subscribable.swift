//
//  Subscribable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol to provide all publisher-like classes access to a corresponding observable.
public protocol ObservableConvertible<Element> {
    /// The type of element emitted by this subscribable.
    associatedtype Element

    /// Convert the current object to an `Observable`.
    func asObservable() -> Observable<Element>
}

/// A protocol to provide all observable-like classes some utilities like subscribeOnce or the operators.
public protocol Subscribable<Element> {
    associatedtype Element
    /// Subscribes an `Observer` to receive elements and completion.
    @discardableResult
    func subscribe<O: Observer<Element>>(_ observer: O) -> Disposable
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
        let observer = AnonymousObserver(onNext: onNext, onComplete: onComplete)
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
