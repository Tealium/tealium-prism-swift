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
    private let handler: SubscriptionHandler

    init(_ subscribe: @escaping SubscriptionHandler) {
        handler = subscribe
    }

    /// Subscribes the observer to be called without checking if it was disposed already.
    override func subscribe<O: Observer<Element>>(_ observer: O) -> Disposable {
        handler(observer)
    }
}
