//
//  Disposable.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/// An protocol representing some long-lived operation that can be disposed.
public protocol Disposable {
    var isDisposed: Bool { get }
    func dispose()
}

public extension Disposable {
    /**
     * Add the disposable to a group so that it can be disposed along the others.
     *
     * - parameter container: The `GroupedDisposable` group that will contain the disposable
     */
    func addTo(_ container: GroupedDisposable) {
        container.add(self)
    }
}

/// A concrete implementation of the `Disposable` protocol that takes a block as an input and calls that block on dispose.
public class Subscription: Disposable {
    fileprivate var unsubscribe: (() -> Void)?
    public var isDisposed: Bool { unsubscribe == nil }
    public init(unsubscribe: @escaping () -> Void) {
        self.unsubscribe = unsubscribe
    }

    public func dispose() {
        unsubscribe?()
        unsubscribe = nil
    }
}

/// A group that contains many disposable objects and disposes them simultaneously.
public protocol GroupedDisposable: Disposable {
    func add(_ disposable: Disposable)
}

/// A concrete implementation of the `GroupedDisposable` protocol that handles disposal of all disposable contained.
public class DisposeContainer: GroupedDisposable {
    private var disposables = [Disposable]()
    public fileprivate(set) var isDisposed: Bool = false
    public init() {}

    /**
     * Adds a disposable to the internal list.
     *
     * If this container is already disposed than the new disposable will be immediately disposed.
     *
     * - parameter disposable: the `Disposable` that will be disposed with this container
     */
    public func add(_ disposable: Disposable) {
        if isDisposed {
            disposable.dispose()
        } else {
            disposables.append(disposable)
        }
    }

    public func dispose() {
        isDisposed = true
        let disposables = self.disposables
        self.disposables = []
        for disposable in disposables {
            disposable.dispose()
        }
    }
}

/// A simple wrapper that disposes the provided subscriptions on a specific queue.
class AsyncDisposer: DisposeContainer {
    let queue: TealiumQueue
    init(disposeOn queue: TealiumQueue) {
        self.queue = queue
    }
    override func dispose() {
        queue.ensureOnQueue {
            self.isDisposed = true
            super.dispose()
        }
    }

    override func add(_ disposable: any Disposable) {
        queue.ensureOnQueue {
            super.add(disposable)
        }
    }
}

/// A subclass of the `DisposeContainer` that will automatically dispose the contained disposables when it is deinitialized.
public class AutomaticDisposer: DisposeContainer {
    deinit {
        dispose()
    }
}
