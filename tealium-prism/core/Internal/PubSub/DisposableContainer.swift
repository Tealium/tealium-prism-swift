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
    private var disposables = [Disposable]()
    fileprivate(set) var isDisposed: Bool = false
    init() {}

    /**
     * Adds a disposable to the internal list.
     *
     * If this container is already disposed than the new disposable will be immediately disposed.
     *
     * - parameter disposable: the `Disposable` that will be disposed with this container
     */
    func add(_ disposable: Disposable) {
        if isDisposed {
            disposable.dispose()
        } else {
            disposables.append(disposable)
        }
    }

    func dispose() {
        isDisposed = true
        let disposables = self.disposables
        self.disposables = []
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

    override func add(_ disposable: any Disposable) {
        queue.ensureOnQueue {
            super.add(disposable)
        }
    }
}

/// A subclass of the `DisposableContainer` that will automatically dispose the contained disposables when it is deinitialized.
class AutomaticDisposer: DisposableContainer {
    deinit {
        dispose()
    }
}
