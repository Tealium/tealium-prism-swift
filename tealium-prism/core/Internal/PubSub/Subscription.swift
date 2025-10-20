//
//  Subscription.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 08/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A concrete implementation of the `Disposable` protocol that takes a block as an input and calls that block on dispose.
class Subscription: Disposable {
    /**
     * A constant `Disposable` which can be used when when no work is actually required to execute upon disposing.
     *
     * `isDisposed` is always `true` and `dispose` is a no-op.
     */
    static let completed: Disposable = {
        let subscription = Subscription { }
        subscription.dispose()
        return subscription
    }()
    fileprivate var unsubscribe: (() -> Void)?
    var isDisposed: Bool { unsubscribe == nil }
    init(unsubscribe: @escaping () -> Void) {
        self.unsubscribe = unsubscribe
    }

    func dispose() {
        unsubscribe?()
        unsubscribe = nil
    }
}
