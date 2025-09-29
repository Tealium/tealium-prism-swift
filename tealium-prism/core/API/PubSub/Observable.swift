//
//  Observable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// An abstract class that allows to subscribe for events until the returned subscription is disposed.
public class Observable<Element>: Subscribable {

    fileprivate init() {
    }

    public func subscribe(_ observer: @escaping Observer) -> Disposable {
        assertionFailure("Subscribe on abstract class should never be called")
        return Subscription { }
    }

    fileprivate func publish(_ element: Element) {
        assertionFailure("Publish on abstract class should never be called")
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
    func subscribeOnce(_ observer: @escaping Observer) -> Disposable {
        first().subscribe(observer)
    }
}

/**
 * A concrete implementation of `Observable` which holds a list of observers that can be added via the subscribe method and forwards them every event it receives.
 *
 * You never create an instance of this class. You always create a `Publisher` and extract an observable with the `asObservable()`.
 * With the publisher you can publish new events that will be received by whoever subscribed to the corresponding observable.
 */
class BaseObservable<Element>: Observable<Element> {

    fileprivate override init() {}
    private let observerList = DisposableItemList<Observer>()

    /// Subscribes a new observer and returns the `Disposable` to remove the observer from the list.
    override func subscribe(_ observer: @escaping Observer) -> Disposable {
        observerList.insert(observer)
    }

    /// A  function that only a Publisher is allowed to call.
    fileprivate override func publish(_ element: Element) {
        observerList.ordered().forEach { observer in
            observer(element)
        }
    }

    func asObservable() -> Observable<Element> {
        self
    }
}

/**
 * A utility class to create custom observables that publish events to the observer with a specific logic.
 *
 * When you create this class from the outside you just pass in the logic that should happen in the subscribe method, defining when, and with what, you can call the observer with the new events.
 * Main purpose of this class is applying some logic that is confined in the subscription handler, without the need to create a custom `Publisher` or `Subject`.
 *
 * See the Operators for examples of how to use this class.
 */
public class CustomObservable<Element>: Observable<Element> {
    public typealias SubscriptionHandler = (@escaping Observer) -> Disposable
    private let subscriptionHandler: SubscriptionHandler
    public init(_ subscribe: @escaping SubscriptionHandler) {
        self.subscriptionHandler = subscribe
    }
    override public func subscribe(_ observer: @escaping Observer) -> Disposable {
        subscriptionHandler(observer)
    }
}

/**
 * A concrete implementation of the `Publisher` that will forward all events published to the contained observable and therefore to the observers subscribed to it.
 */
public class BasePublisher<Element>: Publisher {
    fileprivate let observable: BaseObservable<Element>

    public init() {
        self.observable = BaseObservable<Element>()
    }

    public func publish(_ element: Element) {
        observable.publish(element)
    }

    public func asObservable() -> Observable<Element> {
        observable
    }
}
