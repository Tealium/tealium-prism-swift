//
//  BasePublisher.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A concrete implementation of `Observable` which holds a list of observers that can be added via the subscribe method and forwards them every event it receives.
 *
 * You never create an instance of this class. You always create a `Publisher` and extract an observable with the `asObservable()`.
 * With the publisher you can publish new events that will be received by whoever subscribed to the corresponding observable.
 */
class ObserverListObservable<Element>: Observable<Element> {
    private let observerList = DisposableItemList<AnyObserver<Element>>()
    private var done = false

    override init() {}

    override func subscribe<O: Observer<Element>>(_ observer: O) -> Disposable {
        guard !done else {
            observer.onComplete()
            return CompletedDisposable.shared
        }
        return observerList.append(AnyObserver(observer))
    }

    fileprivate func onNext(_ element: Element) {
        guard !done else { return }
        for observer in observerList.toArray() {
            observer.onNext(element)
        }
    }

    fileprivate func complete() {
        guard !done else { return }
        done = true
        let observers = observerList.toArray()
        observerList.removeAll()
        for observer in observers {
            observer.onComplete()
        }
    }

    func asObservable() -> Observable<Element> {
        self
    }
}

/**
 * A concrete implementation of the `Publisher` that will forward all events published to the contained observable and therefore to the observers subscribed to it.
 */
public class BasePublisher<Element>: Publisher {
    fileprivate let observable: ObserverListObservable<Element>

    /// Creates a new base publisher.
    public init() {
        self.observable = ObserverListObservable<Element>()
    }

    /// Publishes an element to all subscribers.
    /// - Parameter element: The element to publish.
    public func publish(_ element: Element) {
        observable.onNext(element)
    }

    /// Completes this publisher, calling `onComplete` on all current subscribers.
    /// After completion, new subscribers immediately receive `onComplete`.
    public func complete() {
        observable.complete()
    }

    public func asObservable() -> Observable<Element> {
        observable
    }
}
