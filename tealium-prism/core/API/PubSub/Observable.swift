//
//  Observable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A class that allows to subscribe for events until the returned subscription is disposed.
public class Observable<Element>: Subscribable {
    public typealias SubscriptionHandler = (@escaping Observer) -> Disposable
    private let subscriptionHandler: SubscriptionHandler

    init(_ subscribe: @escaping SubscriptionHandler) {
        self.subscriptionHandler = subscribe
    }

    public func subscribe(_ observer: @escaping Observer) -> Disposable {
        subscriptionHandler(observer)
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
