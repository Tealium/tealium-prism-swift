//
//  Array+DataItemInternals.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension Array where Element == DataItem {
    subscript(safe index: Index) -> Iterator.Element? {
        get {
            indices.contains(index) ? self[index] : nil
        }
        set {
            guard index >= 0 else { return }
            while index >= count {
                self.append(.null)
            }
            self[index] = newValue ?? .null
        }
    }

    /// Internal method to extract with path components. Use `JSONPathExtractable.extractDataItem(path:)` instead.
    func extract<Root>(_ components: [JSONPathComponent<Root>]) -> DataItem? {
        guard !components.isEmpty else { return nil }
        var components = components
        guard case let .index(index) = components.removeFirst() else {
            return nil
        }
        let item = self[safe: index]
        return item?.extract(components)
    }
}
