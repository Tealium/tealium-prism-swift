//
//  TealiumObservable.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// An abstract class that allows to subscribe for events until the returned subscription is disposed.
public class TealiumObservable<Element>: TealiumObservableProtocol {

    fileprivate init() {
    }

    public func subscribe(_ observer: @escaping Observer) -> TealiumDisposable {
        assertionFailure("Subscribe on abstract class should never be called")
        return TealiumSubscription { }
    }

    fileprivate func publish(_ element: Element) {
        assertionFailure("Publish on abstract class should never be called")
    }
}

/**
 * A concrete implementation of `TealiumObservable` which holds a list of observers that can be added via the subscribe method and forwards them every event it receives.
 *
 * You never create an instance of this class. You always create a `TealiumPublisher` and extract an observable with the `asObservable()`.
 * With the publisher you can publish new events that will be received by whoever subscribed to the corresponding observable.
 */
class TealiumObservableImpl<Element>: TealiumObservable<Element> {

    fileprivate override init() {}
    private let observerList = ObserverList<Observer>()

    /// Subscribes a new observer and returns the `TealiumDisposable` to remove the observer from the list.
    override func subscribe(_ observer: @escaping Observer) -> TealiumDisposable {
        observerList.insert(observer)
    }

    /// A  function that only a TealiumPublisher is allowed to call.
    fileprivate override func publish(_ element: Element) {
        observerList.orderedObservers().forEach { observer in
            observer(element)
        }
    }

    func asObservable() -> TealiumObservable<Element> {
        self
    }
}

/**
 * A utility class to create custom observables that publish events to the observer with a specific logic.
 *
 * When you create this class from the outside you just pass in the logic that should happen in the subscribe method, defining when, and with what, you can call the observer with the new events.
 * Main purpose of this class is applying some logic that is confined in the subscription handler, without the need to create a custom `TealiumPublisher` or `TealiumSubject`.
 *
 * See the Operators for examples of how to use this class.
 */
public class TealiumObservableCreate<Element>: TealiumObservable<Element> {
    public typealias SubscribeHandler = (@escaping Observer) -> TealiumDisposable
    private let subscribeHandler: SubscribeHandler
    public init(_ subscribe: @escaping SubscribeHandler) {
        self.subscribeHandler = subscribe
    }
    override public func subscribe(_ observer: @escaping Observer) -> TealiumDisposable {
        subscribeHandler(observer)
    }
}

/**
 * A concrete implementation of the `TealiumPublisherProtocol` that will forward all events published to the contained observable and therefore to the observers subscribed to it.
 */
public class TealiumPublisher<Element>: TealiumPublisherProtocol {
    fileprivate let observable: TealiumObservableImpl<Element>

    public init() {
        self.observable = TealiumObservableImpl<Element>()
    }

    public func publish(_ element: Element) {
        observable.publish(element)
    }

    public func asObservable() -> TealiumObservable<Element> {
        observable
    }
}
