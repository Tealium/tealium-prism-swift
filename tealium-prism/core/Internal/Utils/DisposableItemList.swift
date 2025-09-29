//
//  DisposableItemList.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 11/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A class that holds the reference to a list of items and returns a convenient Disposable when a new item is added
class DisposableItemList<Element> {
    private var count: UInt64 = 0
    private var pairs = [(key: UInt64, item: Element)]()

    /**
     * Inserts a new item and returns a Disposable to handle the removal of this item from the list
     *
     * - Parameter item: The generic `Element` to be added
     * - Returns: the `Disposable` to eventually dispose the `Element`
     */
    func insert(_ item: Element) -> Disposable {
        let key = count
        count += 1
        pairs.append((key, item))
        return Subscription { [weak self] in
            self?.remove(at: key)
        }
    }

    private func remove(at key: UInt64) {
        pairs.removeFirst { $0.key == key }
    }

    /// Returns an ordered list of items
    func ordered() -> [Element] {
        pairs.map { $0.item }
    }
}
