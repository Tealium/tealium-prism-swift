//
//  DataItemExtractor+Internals.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension DataItemExtractor {
    /// Internal method to extract with path components. Use `JSONPathExtractable.extractDataItem(path:)` instead.
    func extract<Root>(_ components: [JSONPathComponent<Root>]) -> DataItem? {
        guard !components.isEmpty else { return nil }
        var components = components
        guard case let .key(key) = components.removeFirst() else {
            return nil
        }
        let item = getDataItem(key: key)
        return item?.extract(components)
    }
}
