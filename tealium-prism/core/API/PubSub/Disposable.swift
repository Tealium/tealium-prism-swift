//
//  Disposable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/// An protocol representing some long-lived operation that can be disposed.
public protocol Disposable {
    /// Whether this disposable has been disposed.
    var isDisposed: Bool { get }
    /// Disposes of this resource.
    func dispose()
}

public extension Disposable {
    /**
     * Add the disposable to a group so that it can be disposed along the others.
     *
     * - parameter container: The `CompositeDisposable` group that will contain the disposable
     */
    func addTo(_ container: CompositeDisposable) {
        container.add(self)
    }
}

/// A group that contains many disposable objects and disposes them simultaneously.
public protocol CompositeDisposable: Disposable {
    /// Adds a disposable to this composite.
    /// - Parameter disposable: The disposable to add.
    func add(_ disposable: Disposable)
}
