//
//  Linkable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A `Disposable` that can be linked to another `Disposable`.
protocol Linkable: Disposable {

    /// Links the provided `disposable` so that it will be disposed when this class is disposed.
    ///
    /// This method must not be called again while another disposable is currently linked.
    /// If this class is already disposed, the provided `disposable` is disposed immediately instead of linking.
    /// - Warning: Conforming types may precondition-fail if called while another disposable is currently linked.
    func link(_ disposable: any Disposable)
}

/// A protocol combining `Linkable` and `Observer` for operator observer classes.
protocol LinkableObserver<Element>: Linkable, Observer {}

final class SingleLinkable: Linkable {
    private var upstream: (any Disposable)?

    private(set) var isDisposed: Bool = false

    func link(_ disposable: any Disposable) {
        if isDisposed {
            disposable.dispose()
            return
        }
        precondition(upstream == nil, "Cannot link a new disposable while another disposable is still linked")
        upstream = disposable
    }

    func dispose() {
        guard !isDisposed else { return }
        isDisposed = true
        upstream?.dispose()
        upstream = nil
    }
}
