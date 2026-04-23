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
     * Creates a custom observable that can call `Observer` callbacks with values of type `Element`.
     *
     * Use this method to create different behaviors upon `Observable` subscription.
     *
     * - parameter subscriptionHandler: The code run every time the returned `Observable` is subscribed upon.
     * Within this block you can call the `Observer` block with values of type `Element`.
     * - returns: An `Observable` that can be subscribed upon.
     * Every time someone subscribes to this `Observable` the `subscriptionHandler` will be invoked.
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
     * - Returns: a `Observable` that, when a new observer subscribes, will call the asyncFunction and publish a new event to the subscribers when the function completes.
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
     * - Returns: a `Observable` that, when a new observer subscribes, will call the asyncFunction and publish a new event to the subscribers when the function completes.
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
                observer(element)
            }
            observer.onComplete()
            return Disposables.disposed()
        }
    }

    /// Returns an empty observable that never reports anything
    static func empty<Element>() -> Observable<Element> {
        Self.from([])
    }

    /**
     * Returns a single observable with an array of Elements from the provided array of elements
     *
     * The first element published from the returned observable will be published when all the observables provided emit at list one element.
     * All subsequent changes to any observable will be emitted one by one.
     */
    static func combineLatest<Element>(_ observables: [Observable<Element>]) -> Observable<[Element]> {
        IterableCombineLatestObservable(observables: observables)
    }
}
