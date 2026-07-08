//
//  Array+Extensions.swift
//  tealium-prism
//
//  Created by Denis Guzov on 10/07/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension Array {
    /**
     * Return the `Element` to avoid deinit of that element, which might have side effects and could
     * potentially cause synchronous reentrancy and therefore cause a crash on `remove(at:)`.
     *
     * This was happening on `DisposableItemList.removeFirst` which was causing a deinit of the
     * element, which would cause an `AutomaticDisposer.deinit`, which would cause that same list to remove
     * one of its elements, causing the reentrance and the simultaneous accesses crash.
     */
    @discardableResult
    mutating func removeFirst(where shouldBeRemoved: (Element) throws -> Bool) rethrows -> Element? {
        try firstIndex(where: shouldBeRemoved).map { remove(at: $0) }
    }

    func diff<T: Equatable>(_ other: Self, by key: KeyPath<Element, T>) -> Self {
        filter { element in
            !other.contains(where: { $0[keyPath: key] == element[keyPath: key] })
        }
    }

    func partitioned(by belongsInFirstPartition: (Element) throws -> Bool) rethrows -> (Self, Self) {
        var first = [Element]()
        var second = [Element]()
        for element in self {
            if try belongsInFirstPartition(element) {
                first.append(element)
            } else {
                second.append(element)
            }
        }
        return (first, second)
    }

    func removingDuplicates<Value: Hashable>(by keyPath: KeyPath<Element, Value>,
                                             and shouldBeDiscarded: (Element) -> Bool = { _ in true }) -> Self {
        var valueSet = Set<Value>()
        return filter { element in
            valueSet.insert(element[keyPath: keyPath]).inserted || !shouldBeDiscarded(element)
        }
    }
}
