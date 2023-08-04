//
//  TealiumDisposable.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/// An protocol representing some long-lived operation that can be disposed.
public protocol TealiumDisposable {
    var isDisposed: Bool { get }
    func dispose()
}

public extension TealiumDisposable {
    /**
     * Add the disposable to a group so that it can be disposed along the others.
     *
     * - parameter container: The `TealiumGroupedDisposable` group that will contain the disposable
     */
    func addTo(_ container: TealiumGroupedDisposable) {
        container.add(self)
    }
}

/// A concrete implementation of the `TealiumDisposable` protocol that takes a block as an input and calls that block on dispose.
public class TealiumSubscription: TealiumDisposable {
    fileprivate var unsubscribe: () -> Void
    public private(set) var isDisposed: Bool = false
    public init(unsubscribe: @escaping () -> Void) {
        self.unsubscribe = unsubscribe
    }

    public func dispose() {
        unsubscribe()
        isDisposed = true
    }
}

/// A group that contains many disposable objects and disposes them simultaneously.
public protocol TealiumGroupedDisposable: TealiumDisposable {
    func add(_ disposable: TealiumDisposable)
}

/// A concrete implementation of the `TealiumGroupedDisposable` protocol that handles disposal of all disposable contained.
public class TealiumDisposeContainer: TealiumGroupedDisposable {
    private var disposables = [TealiumDisposable]()
    public private(set) var isDisposed: Bool = false
    public init() {}

    /**
     * Adds a disposable to the internal list.
     *
     * If this container is already disposed than the new disposable will be immediately disposed.
     *
     * - parameter disposable: the `TealiumDisposable` that will be disposed with this container
     */
    public func add(_ disposable: TealiumDisposable) {
        if isDisposed {
            disposable.dispose()
        } else {
            disposables.append(disposable)
        }
    }

    public func dispose() {
        let disposables = self.disposables
        self.disposables = []
        for disposable in disposables {
            disposable.dispose()
        }
        isDisposed = true
    }
}

/// A subclass of the `TealiumDisposeContainer` that will automatically dispose the contained disposables when it is deinitialized.
public class TealiumAutomaticDisposer: TealiumDisposeContainer {
    deinit {
        dispose()
    }
}
