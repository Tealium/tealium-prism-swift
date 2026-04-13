//
//  NonDisposalCheckingObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/03/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism

/// A subclass that skips the check for disposed observers.
class NonDisposalCheckingObservable<Element>: Observable<Element> {
    /// Another handler that can be used here instead
    private let nonCheckingSubscriptionHandler: SubscriptionHandler

    override init(_ subscribe: @escaping SubscriptionHandler) {
        nonCheckingSubscriptionHandler = subscribe
        super.init(subscribe)
    }

    /// Subscribes the observer to be called without checking if it was disposed already.
    override func subscribe(_ observer: @escaping Observer) -> Disposable {
        nonCheckingSubscriptionHandler(observer)
    }
}
