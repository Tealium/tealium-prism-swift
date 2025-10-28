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

    /// Convert the current object to an `Observable`
    func asObservable() -> Observable<Element>
}

/// A protocol to provide all observable-like classes some utilities like subscribeOnce or the operators.
public protocol Subscribable<Element>: ObservableConvertible {
    /// A callback to receive the values you subscribed to.
    typealias Observer = (Element) -> Void

    /**
     * Subscribe a callback to receive the `Element`.
     *
     * - parameter observer: The callback called with the `Element`,
     * - returns: A `Disposable` that can be disposed to stop the observer from being called.
     */
    func subscribe(_ observer: @escaping Observer) -> any Disposable
}

public extension Subscribable {
    func asObservable() -> Observable<Element> {
        Observable<Element> { observer in self.subscribe(observer) }
    }

    /// Subscribe a `Subject` to this `Subscribable`.
    func subscribe(_ subject: Subject<Element>) -> any Disposable {
        subscribe { element in
            subject.publish(element)
        }
    }
}
