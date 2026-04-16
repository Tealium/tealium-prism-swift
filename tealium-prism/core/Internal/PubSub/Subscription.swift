//
//  Subscription.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 08/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A concrete implementation of the `Disposable` protocol that takes a block as an input and calls that block on dispose.
class Subscription: DisposableContainer {
    private var onDispose: (() -> Void)?
    init(onDispose: @escaping () -> Void) {
        self.onDispose = onDispose
    }

    override func dispose() {
        onDispose?()
        onDispose = nil
        super.dispose()
    }
}
