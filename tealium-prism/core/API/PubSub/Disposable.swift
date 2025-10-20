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
    var isDisposed: Bool { get }
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
    func add(_ disposable: Disposable)
}
