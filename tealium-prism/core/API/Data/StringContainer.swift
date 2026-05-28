//
//  StringContainer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A container for a string value.
///
/// ## JSON Representation
///
/// ```json
/// {
///   "value": "some_string"
/// }
/// ```
///
/// When used as a filter in a ``Condition``, the value is the target string
/// for the comparison operator.
public struct StringContainer: Equatable {
    enum Keys {
        static let value = "value"
    }

    /// The string value stored in this container. Will be parsed as a number if necessary.
    public let value: String

    /// Creates a string container with the specified value.
    /// - Parameter value: The string value to store.
    public init(_ value: String) {
        self.value = value
    }
}

extension StringContainer: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        [
            Keys.value: value
        ]
    }
}
