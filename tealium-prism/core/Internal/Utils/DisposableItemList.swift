//
//  DisposableItemList.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 11/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

private struct DisposableElement<Element> {
    let key: UInt64
    let item: Element
}

/// A class that holds the reference to a list of items and returns a convenient Disposable when a new item is added
class DisposableItemList<Element>: Sequence {
    typealias Iterator = IndexingIterator<[Element]>
    private var key: UInt64 = 0
    fileprivate var pairs = [DisposableElement<Element>]()

    var count: Int {
        pairs.count
    }

    /**
     * Inserts a new item and returns a Disposable to handle the removal of this item from the list
     *
     * - Parameter item: The generic `Element` to be added
     * - Returns: the `Disposable` to eventually dispose the `Element`
     */
    func insert(_ item: Element) -> Disposable {
        let key = self.key
        self.key += 1
        pairs.append(DisposableElement(key: key, item: item))
        return Subscription { [weak self] in
            self?.remove(at: key)
        }
    }

    private func remove(at key: UInt64) {
        pairs.removeFirst { $0.key == key }
    }

    /// Returns an Array of the items in this list.
    func toArray() -> [Element] {
        pairs.map { $0.item }
    }

    func makeIterator() -> IndexingIterator<[Element]> {
        toArray().makeIterator()
    }
}
