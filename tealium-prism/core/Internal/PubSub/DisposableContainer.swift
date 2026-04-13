//
//  DisposableContainer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 08/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A concrete implementation of the `Disposable` protocol that handles disposal of all disposable contained.
class DisposableContainer: Disposable {
    private(set) var disposables = [Disposable]()
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
    func add(_ disposable: Disposable) -> Self {
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

    /**
     * Adds a `Disposable` to this `Disposable` and vice versa.
     *
     * This will create a retain cycle between the two `Disposable`s.
     * To clear the cycle you need to dispose either one of the `Disposable`s.
     *
     *- Parameter disposable: The disposable to add to self and in which self is added to.
     */
    func crossAdd(_ disposable: Disposable) {
        guard !isDisposed else {
            disposable.dispose()
            return
        }
        guard !disposable.isDisposed else {
            self.dispose()
            return
        }
        disposables.append(disposable)
        disposable.add(self)
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

    override func crossAdd(_ disposable: Disposable) {
        queue.ensureOnQueue {
            super.crossAdd(disposable)
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
struct CompletedDisposable: Disposable {
    static let shared = CompletedDisposable()
    let isDisposed = true

    private init() {}

    func dispose() {}

    @discardableResult
    func add(_ disposable: Disposable) -> Self {
        disposable.dispose()
        return self
    }
}
