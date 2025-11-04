//
//  ValueContainer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// A container for a generic value that is stored in a `String`.
public struct ValueContainer: Equatable {
    enum Keys {
        static let value = "value"
    }

    /// The string representation of a value. Will be parsed as a number if necessary.
    public let value: String

    /// Creates a value container with the specified string value.
    /// - Parameter value: The string value to store.
    public init(_ value: String) {
        self.value = value
    }
}

extension ValueContainer: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        [
            Keys.value: value
        ]
    }
}
