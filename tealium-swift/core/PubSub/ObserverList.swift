//
//  ObserverList.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 11/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A class that holds the reference to a list of observers and returns a convenient Disposable when a new observer is added
class ObserverList<Observer> {
    private var count: UInt64 = 0
    private var observers = [(UInt64, Observer)]()

    /**
     * Inserts a new observer and returns a TealiumDisposable to handle the removal of this observer from the list
     *
     * - Parameter observer: The generic `Observer` to be added
     * - Returns: the `TealiumDisposable` to eventually dispose the `Observer`
     */
    func insert(_ observer: Observer) -> TealiumDisposable {
        let key = count
        count += 1
        observers.append((key, observer))
        return TealiumSubscription { [weak self] in
            self?.removeObserver(key: key)
        }
    }

    private func removeObserver(key: UInt64) {
        observers.removeAll { $0.0 == key }
    }

    /// Returns an ordered list of observers
    func orderedObservers() -> [Observer] {
        observers.map { $0.1 }
    }
}
