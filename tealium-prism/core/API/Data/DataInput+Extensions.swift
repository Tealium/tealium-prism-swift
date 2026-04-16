//
//  DataInput+Extensions.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 19/09/24.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK: - DataInput conformances

extension NSNull: DataInput, DataInputConvertible {}
extension Decimal: DataInput, DataInputConvertible {}
extension Double: DataInput, DataInputConvertible {}
extension Float: DataInput, DataInputConvertible {}
extension Int: DataInput, DataInputConvertible {}
extension Int64: DataInput, DataInputConvertible {}
extension Bool: DataInput, DataInputConvertible {}
extension String: DataInput, DataInputConvertible {}
extension NSNumber: DataInput, DataInputConvertible {}
extension Array: DataInput where Element == DataInput {}
extension Dictionary: DataInput where Key == String, Value == DataInput { }

// MARK: - DataInputConvertible default implementations

public extension DataInputConvertible where Self: DataInput {
    func toDataInput() -> DataInput {
        self
    }
}
extension Array: DataInputConvertible where Element: DataInputConvertible {
    public func toDataInput() -> DataInput {
        self.map { $0.toDataInput() }
    }
}
extension Dictionary: DataInputConvertible where Key == String, Value: DataInputConvertible {
    public func toDataInput() -> DataInput {
        self.mapValues { $0.toDataInput() }
    }
}

// MARK: - Optional DataInput helpers

public extension Optional where Wrapped: DataInput {
    /// Returns a `DataItem` that contains the wrapped value or `NSNull`, if the wrapped value was `nil`.
    func asDataItem() -> DataItem {
        flatMap { DataItem(value: $0) } ?? .null
    }
}

// MARK: - Array conversion

public extension Array {
    /// Converts an array of optional `DataInput`-conforming values to `[DataItem]`,
    /// preserving positions by replacing each `nil` with `.null` (i.e. `NSNull`).
    ///
    /// Use this when you want to keep `nil` entries as explicit nulls in a DataObject, for example:
    /// ```swift
    /// let scores: [Int?] = [42, nil, 7]
    /// let dataObject: DataObject = ["scores": scores.asDataArray()]
    /// // → ["scores": [42, NSNull(), 7]]
    /// ```
    ///
    /// If you want to **drop** `nil` entries instead, use `compactMap`:
    /// ```swift
    /// let dataObject: DataObject = ["scores": scores.compactMap { $0 }]
    /// // → ["scores": [42, 7]]
    /// ```
    func asDataArray<T: DataInput>() -> [DataItem] where Element == T? {
        map { $0.asDataItem() }
    }
}

public extension Array where Element == DataInput? {
    /// Converts an array of `[DataInput?]` (existential optional) values to `[DataItem]`,
    /// preserving positions by replacing each `nil` with `.null` (i.e. `NSNull`).
    ///
    /// Use this when you want to keep `nil` entries as explicit nulls in a DataObject, for example:
    /// ```swift
    /// let scores: [DataInput?] = [42, nil, "value"]
    /// let dataObject: DataObject = ["scores": scores.asDataArray()]
    /// // → ["scores": [42, NSNull(), "value"]]
    /// ```
    ///
    /// If you want to **drop** `nil` entries instead, use `compactMap`:
    /// ```swift
    /// let dataObject: DataObject = ["scores": scores.compactMap { $0 }]
    /// // → ["scores": [42, "value"]]
    /// ```
    func asDataArray() -> [DataItem] {
        map { $0.flatMap { DataItem(value: $0) } ?? .null }
    }
}

// MARK: - Dictionary conversion

public extension Dictionary where Key == String {
    /// Converts a dictionary of optional `DataInput`-conforming values dictionary to `[String: DataItem]`,
    /// preserving all keys by replacing each `nil` value with `.null` (i.e. `NSNull`).
    ///
    /// Use this when you want to keep `nil` values as explicit nulls in a DataObject, for example:
    /// ```swift
    /// let attrs: [String: String?] = ["name": "Alice", "email": nil]
    /// let dataObject: DataObject = ["user": attrs.asDataDictionary()]
    /// // → ["user": ["name": "Alice", "email": NSNull()]]
    /// ```
    ///
    /// If you want to **drop** keys with `nil` values instead, use `compactMapValues`:
    /// ```swift
    /// let dataObject: DataObject = ["user": attrs.compactMapValues { $0 }]
    /// // → ["user": ["name": "Alice"]]
    /// ```
    func asDataDictionary<T: DataInput>() -> [String: DataItem] where Value == T? {
        mapValues { $0.asDataItem() }
    }
}

public extension Dictionary where Key == String, Value == DataInput? {
    /// Converts a `[String: DataInput?]` (existential optional) dictionary to `[String: DataItem]`,
    /// preserving all keys by replacing each `nil` value with `.null` (i.e. `NSNull`).
    ///
    /// Use this when you want to keep `nil` values as explicit nulls in a DataObject, for example:
    /// ```swift
    /// let attrs: [String: DataInput?] = ["name": "Alice", "email": nil, "age": 25]
    /// let dataObject: DataObject = ["user": attrs.asDataDictionary()]
    /// // → ["user": ["name": "Alice", "email": NSNull(), "age": 25]]
    /// ```
    ///
    /// If you want to **drop** keys with `nil` values instead, use `compactMapValues`:
    /// ```swift
    /// let dataObject: DataObject = ["user": attrs.compactMapValues { $0 }]
    /// // → ["user": ["name": "Alice", "age": 25]]
    /// ```
    func asDataDictionary() -> [String: DataItem] {
        mapValues { $0.flatMap { DataItem(value: $0) } ?? .null }
    }
}
