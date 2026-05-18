//
//  AnonymousObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A concrete `Observable` backed by a closure that runs for each subscriber.
class AnonymousObservable<Element>: Observable<Element> {
    private let handler: SubscriptionHandler

    init(_ handler: @escaping SubscriptionHandler) {
        self.handler = handler
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> Disposable {
        handler(observer)
    }
}
