//
//  ValueContainer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// A container for a generic value that is stored in a `String`.
public struct ValueContainer {
    enum Keys {
        static let value = "value"
    }

    /// The string representation of a value. Will be parsed as a number if necessary.
    let value: String

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

extension ValueContainer {
    struct Converter: DataItemConverter {
        typealias Convertible = ValueContainer
        func convert(dataItem: DataItem) -> Convertible? {
            guard let object = dataItem.getDataDictionary(),
                  let value = object.get(key: Keys.value, as: String.self) else {
                return nil
            }
            return ValueContainer(value)
        }
    }

    static let converter = Converter()
}

extension ValueContainer: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    /// Creates a `ValueContainer` from a string literal.
    /// - Parameter value: The string literal to use as the variable name.
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}
