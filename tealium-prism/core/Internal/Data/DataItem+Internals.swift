//
//  DataItem+Internals.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension DataItem {
    /// Internal method to extract with path components. Use `JSONPathExtractable.extractDataItem(path:)` instead on a `DataObject` or on an array of `DataItem`s.
    func extract<Root>(_ components: [JSONPathComponent<Root>]) -> DataItem? {
        guard !components.isEmpty else {
            return self
        }
        if let dictionary = getDataDictionary() {
            return dictionary.extract(components)
        } else if let array = getDataArray() {
            return array.extract(components)
        } else {
            return nil
        }
    }
}
