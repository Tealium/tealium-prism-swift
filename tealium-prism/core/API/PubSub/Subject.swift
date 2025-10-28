//
//  Subject.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A `Publisher` that can be also subscribed to.
 *
 * You can use it as a property wrapper to make the publishing private in the class where it's contained, but still expose an `Observable`
 * to the other classes.
 */
@propertyWrapper
public class Subject<Element>: BasePublisher<Element>, Subscribable {
    /// The wrapped observable value for property wrapper usage.
    public var wrappedValue: Observable<Element> {
        asObservable()
    }

    public func subscribe(_ observer: @escaping Observer) -> Disposable {
        asObservable().subscribe(observer)
    }

    /**
     * Subscribes the observer only once and then automatically disposes it.
     *
     * This is meant to be used when you only need one observer to be registered once.
     * Use the standalone `first()` operator if multiple observers all need to register for one event.
     *
     * - returns: a `Disposable` that can be used to dispose this observer before the first event is sent to the observer, in case it's not needed any longer.
     */
    @discardableResult
    public func subscribeOnce(_ observer: @escaping Observer) -> Disposable {
        asObservable().subscribeOnce(observer)
    }
}
