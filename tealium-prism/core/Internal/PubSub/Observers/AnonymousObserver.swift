//
//  AnonymousObserver.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 13/05/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A simple callback-based observer for internal use in operator chains.
///
/// Not thread-safe and has no disposal guard — it relies on an external wrapper (`UnsubscribingObserver`,
/// `DisposableObserver`) to prevent calls after completion/disposal. The wrapper ensures `onNext`/`onComplete`
/// are never called once the subscription is terminated, so this class doesn't need `isDisposed` state.
///
/// `stop()` nils callbacks to release captured references, but is not required for correctness — it's
/// called by `onComplete` as a memory optimization to eagerly free closures that may capture heavy objects.
class AnonymousObserver<Element>: Observer {
    private var _onNext: ((Element) -> Void)?
    private var _onComplete: (() -> Void)?

    init(onNext: @escaping (Element) -> Void, onComplete: @escaping () -> Void) {
        self._onNext = onNext
        self._onComplete = onComplete
    }

    func onNext(_ element: Element) {
        _onNext?(element)
    }

    func onComplete() {
        let onComplete = _onComplete
        stop()
        onComplete?()
    }

    func stop() {
        _onNext = nil
        _onComplete = nil
    }
}
