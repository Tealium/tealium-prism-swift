//
//  Subject.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A subscribable source that can emit events to its observers and be an observer itself.
 *
 * You can use it as a property wrapper to make the emission private in the class where it's contained, but still expose an `Observable`
 * to the other classes.
 */
@propertyWrapper
public class Subject<Element>: Subscribable, Observer, ObservableConvertible {
    fileprivate let observable: ObserverListObservable<Element>

    /// Creates a new subject.
    public init() {
        self.observable = ObserverListObservable<Element>()
    }

    /// The wrapped observable value for property wrapper usage.
    public var wrappedValue: Observable<Element> {
        asObservable()
    }

    /// Emits an element to all subscribers.
    /// - Parameter element: The element to emit.
    public func onNext(_ element: Element) {
        observable.onNext(element)
    }

    /// Completes this subject, calling `onComplete` on all current subscribers.
    /// After completion, new subscribers immediately receive `onComplete`.
    public func onComplete() {
        observable.onComplete()
    }

    public func asObservable() -> Observable<Element> {
        observable
    }

    public func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        asObservable().subscribe(observer)
    }

}

public extension Subject where Element == Void {
    /// Emits a `Void` event to all subscribers.
    func onNext() {
        onNext(())
    }
}

public extension Subject {
    /**
     * Subscribes the observer only once and then automatically disposes it.
     *
     * This is meant to be used when you only need one observer to be registered once.
     * Use the standalone `first()` operator if multiple observers all need to register for one event.
     *
     * - returns: a `Disposable` that can be used to dispose this observer before the first event is sent to the observer, in case it's not needed any longer.
     */
    @discardableResult
    func subscribeOnce(_ observer: @escaping (Element) -> Void) -> any Disposable {
        asObservable().subscribeOnce(observer)
    }
}
