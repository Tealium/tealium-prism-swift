//
//  Observables.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Contains factory methods for creating common `Observable` instances for use with the Tealium SDK.
 */
public enum Observables {
}

public extension Observables {

    /**
     * Creates a custom observable from a subscription handler.
     *
     * The handler is invoked every time the returned `Observable` is subscribed to.
     * Within the handler, call `observer.onNext(_:)` to emit elements and `observer.onComplete()` to signal termination.
     *
     * The `Disposable` returned from the handler is disposed when the subscription is externally disposed,
     * allowing the handler to cancel any ongoing work.
     *
     * - parameter subscriptionHandler: A block invoked on each subscription. Receives an `Observer` and must return
     *   a `Disposable` that will be disposed when the subscription is cancelled.
     * - returns: An `Observable` that invokes `subscriptionHandler` on each subscription.
     */
    static func create<Element>(subscriptionHandler: @escaping Observable<Element>.SubscriptionHandler) -> Observable<Element> {
        AnonymousObservable(subscriptionHandler)
    }
    /**
     * Returns an observable that will send only one event once the asyncFunction has completed.
     *
     * - Parameter asyncFunction: is the function that needs to be called and needs to report the completion to the provided observer.
     *  This function will only be called when an observer subscribes to the returned Observable. Every subscription will cause the asyncFunction to be called again.
     *
     * - Returns: a `Observable` that, when a new observer subscribes, will call the asyncFunction and emit a new event to the subscribers when the function completes.
     */
    static func callback<Element>(from asyncFunction: @escaping (@escaping (Element) -> Void) -> Void) -> Observable<Element> {
        CallbackObservable { observer in
            asyncFunction(observer.onNext(_:))
            return Disposables.disposed()
        }
    }

    /**
     * Returns an observable that will send only one event once the asyncFunction has completed.
     *
     * - Parameter asyncFunction: is the function that needs to be called and needs to report the completion to the provided observer.
     *  This function will only be called when an observer subscribes to the returned Observable. Every subscription will cause the asyncFunction to be called again.
     *  The `Disposable` returned by this function will be disposed if the subscription is disposed before the event is emitted, allowing to cancel the ongoing work.
     *
     * - Returns: a `Observable` that, when a new observer subscribes, will call the asyncFunction and emit a new event to the subscribers when the function completes.
     */
    static func callback<Element>(from asyncFunction: @escaping (@escaping (Element) -> Void) -> Disposable) -> Observable<Element> {
        CallbackObservable { observer in
            asyncFunction(observer.onNext(_:))
        }
    }

    /// Returns an observable that just reports the provided elements in order to each new subscriber.
    static func just<Element>(_ elements: Element...) -> Observable<Element> {
        Self.from(elements)
    }

    /// Returns an observable that just reports the provided elements in order to each new subscriber.
    static func from<Element>(_ elements: [Element]) -> Observable<Element> {
        self.create { observer in
            for element in elements {
                observer.onNext(element)
            }
            observer.onComplete()
            return Disposables.disposed()
        }
    }

    /// Returns an observable that completes immediately without emitting any elements.
    static func empty<Element>() -> Observable<Element> {
        Self.from([])
    }

    /**
     * Combines the latest values from all provided observables into an array.
     *
     * The first emission occurs once every source observable has emitted at least one element.
     * After that, a new array is emitted each time any source emits a new value.
     *
     * **Completion:** Completes when all sources complete, or early if any source completes
     * without ever having emitted a value (since a full combination can never be formed).
     */
    static func combineLatest<Element>(_ observables: [Observable<Element>]) -> Observable<[Element]> {
        IterableCombineLatestObservable(observables: observables)
    }
}
