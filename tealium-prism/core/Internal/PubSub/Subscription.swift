//
//  Subscription.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 08/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A concrete implementation of the `Disposable` protocol that takes a block as an input and calls that block on dispose.
class Subscription: Disposable {
    private var onDispose: (() -> Void)?
    private(set) var isDisposed = false

    init(onDispose: @escaping () -> Void) {
        self.onDispose = onDispose
    }

    func dispose() {
        guard !isDisposed else { return }
        isDisposed = true
        onDispose?()
        onDispose = nil
    }
}
