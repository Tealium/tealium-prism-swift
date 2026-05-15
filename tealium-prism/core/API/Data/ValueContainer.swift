//
//  ValueContainer.swift
//  tealium-prism
//
//  Created by Den Guzov on 28/01/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A container for a value that is stored as a `DataItem`.
///
/// ## JSON Representation
///
/// The value can be any valid JSON type:
///
/// ```json
/// { "value": "hello" }
/// ```
///
/// ```json
/// { "value": 42 }
/// ```
///
/// ```json
/// { "value": ["red", "green", "blue"] }
/// ```
public struct ValueContainer {
    enum Keys {
        static let value = "value"
    }

    /// The value stored in this container
    public let value: DataItem

    /// Creates a value container with the specified value
    /// - Parameter value: The value to store
    public init(_ value: DataInput) {
        self.init(item: DataItem(value: value))
    }

    /// Internal initializer that takes a `DataItem` directly
    /// - Parameter item: The `DataItem` to store
    init(item: DataItem) {
        self.value = item
    }
}

extension ValueContainer: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        return [Keys.value: value]
    }
}
