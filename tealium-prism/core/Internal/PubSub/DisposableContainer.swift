//
//  DisposableContainer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 08/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A concrete implementation of the `CompositeDisposable` protocol that handles disposal of all disposable contained.
class DisposableContainer: CompositeDisposable {
    private(set) var disposables = [any Disposable]()
    private(set) var isDisposed: Bool = false

    var count: Int {
        disposables.count
    }

    init() {}

    /**
     * Adds a disposable to the internal list.
     *
     * If this container is already disposed than the new disposable will be immediately disposed.
     *
     * - parameter disposable: the `Disposable` that will be disposed with this container
     */
    @discardableResult
    func add(_ disposable: any Disposable) -> Self {
        guard !isDisposed else {
            disposable.dispose()
            return self
        }
        guard !disposable.isDisposed else {
            return self
        }
        disposables.append(disposable)
        return self
    }

    func remove(_ disposable: any Disposable) {
        disposables.removeAll { $0 === disposable }
    }

    func dispose() {
        isDisposed = true
        let disposables = self.disposables
        self.disposables.removeAll()
        for disposable in disposables {
            disposable.dispose()
        }
    }
}

/// A simple wrapper that synchronizes adding and disposing the `Disposable` children on a specific queue.
class AsyncDisposableContainer: DisposableContainer {
    let queue: TealiumQueue
    init(queue: TealiumQueue) {
        self.queue = queue
    }
    override func dispose() {
        queue.ensureOnQueue {
            super.dispose()
        }
    }

    @discardableResult
    override func add(_ disposable: any Disposable) -> Self {
        queue.ensureOnQueue {
            super.add(disposable)
        }
        return self
    }

    override func remove(_ disposable: any Disposable) {
        queue.ensureOnQueue {
            super.remove(disposable)
        }
    }
}

/// A subclass of the `DisposableContainer` that will automatically dispose the contained disposables when it is deinitialized.
class AutomaticDisposer: DisposableContainer {
    deinit {
        dispose()
    }
}

/**
 * A constant `Disposable` which can be used when when no work is actually required to execute upon disposing.
 *
 * `isDisposed` is always `true` and `dispose` is a no-op.
 */
final class CompletedDisposable: Disposable {
    static let shared = CompletedDisposable()
    let isDisposed = true

    private init() {}

    func dispose() {}
}
