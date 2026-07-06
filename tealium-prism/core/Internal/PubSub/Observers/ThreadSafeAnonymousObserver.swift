//
//  AnonymousObserver.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A thread-safe callback-based observer used at the public subscription boundary
/// (`Subscribable.subscribe(onNext:onComplete:)`). Returned directly as the `Disposable`.
///
/// Thread-safe because `subscribe` is typically called from an unknown thread while
/// upstream emissions and completion arrive on a different queue (e.g. via `subscribeOn`),
/// creating a race between `link` and `onComplete`/`dispose`.
///
/// Unlike `AnonymousObserver`, this class:
/// - Guards all paths with `isDisposed` under a lock, since it has no external wrapper protecting it.
/// - Manages the upstream `Disposable` via `link`/`dispose`, handling the assign-after-complete race.
/// - Nils callbacks on both completion and disposal to release user-captured references (view controllers, etc.).
class ThreadSafeAnonymousObserver<Element>: LinkableObserver {
    private var upstream: (any Disposable)?
    private(set) var isDisposed = false
    private let lock = SynchronizeLock()

    private var _onNext: ((Element) -> Void)?
    private var _onComplete: (() -> Void)?

    init(onNext: @escaping (Element) -> Void, onComplete: @escaping () -> Void) {
        self._onNext = onNext
        self._onComplete = onComplete
    }

    func onNext(_ element: Element) {
        let onNext: ((Element) -> Void)? = lock.synchronize {
            guard !isDisposed else { return nil }
            return _onNext
        }
        onNext?(element)
    }

    func onComplete() {
        let onComplete: (() -> Void)? = lock.synchronize {
            guard !isDisposed else { return nil }
            defer { stop() }
            return _onComplete
        }
        guard let onComplete else { return }
        onComplete()
        dispose()
    }

    private func stop() {
        _onNext = nil
        _onComplete = nil
    }

    func dispose() {
        let upstream: (any Disposable)? = lock.synchronize {
            guard !isDisposed else { return nil }
            isDisposed = true
            stop()
            defer { self.upstream = nil }
            return self.upstream
        }
        upstream?.dispose()
    }

    func link(_ disposable: any Disposable) {
        let shouldDispose: Bool = lock.synchronize {
            if isDisposed {
                return true
            }
            upstream = disposable
            return false
        }
        if shouldDispose {
            disposable.dispose()
        }
    }
}
