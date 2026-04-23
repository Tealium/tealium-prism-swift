//
//  UpstreamLinkable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A `Disposable` that can be linked to an upstream subscription.
/// When disposed, it also disposes the linked upstream.
/// If already disposed when `setUpstream` is called, the upstream is disposed immediately.
/// If the upstream is already disposed when `setUpstream` is called, `self` is disposed immediately.
protocol UpstreamLinkable: Disposable {
    func setUpstream(_ disposable: any Disposable)
}

/// A protocol combining `UpstreamLinkable` and `Observer` for operator observer classes.
protocol LinkableObserver<Element>: UpstreamLinkable, Observer {}

class UpstreamLinkableImpl: UpstreamLinkable {
    private var upstream: (any Disposable)?
    private(set) var isDisposed = false

    func setUpstream(_ disposable: any Disposable) {
        if isDisposed {
            disposable.dispose()
            return
        }
        upstream = disposable
    }

    // TODO: Remove after we separate `Disposable` and `CompositeDisposable`
    @discardableResult
    @available(*, deprecated)
    func add(_ disposable: any Disposable) -> Self { self }

    func dispose() {
        guard !isDisposed else { return }
        isDisposed = true
        upstream?.dispose()
        upstream = nil
    }
}
