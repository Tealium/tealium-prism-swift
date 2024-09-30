//
//  DataItemExtractor.swift
//  Pods
//
//  Created by Enrico Zannini on 02/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A container of key-value pairs that can return a `DataItem` for a given `String` key.
public protocol DataItemExtractor {
    /// - returns: A `DataItem` if one can be found for the given key.
    func getDataItem(key: String) -> DataItem?
}

extension Dictionary: DataItemExtractor where Key == String, Value == DataItem {
    public func getDataItem(key: String) -> DataItem? {
        self[key]
    }
}

public extension DataItemExtractor {
    /**
     * Returns the data at the given key in the requested type if the conversion is possible.
     *
     * Supported types are:
     * - `Double`
     * - `Float`
     * - `Int`
     * - `Int64`
     * - `Bool`
     * - `String`
     * - `NSNumber`
     *
     * You can call this method without parameters if the return type can be inferred:
     *  ``` swift
     * let dataExtractor: DataItemExtractor = ...
     * let anInt: Int? = dataExtractor.get(key: "someKey")
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataExtractor: DataItemExtractor = ...
     * let anInt = dataExtractor.get(key: "someKey", as: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangebely and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataExtractor: DataItemExtractor = DataObject(dictionary: ["someKey": nsNumber])
     * let aDouble: Double? = dataExtractor.get(key: "someKey") // Double(1.5)
     * let anInt: Int? = dataExtractor.get(key: "someKey") // Int(1)
     *  ```
     */
    func get<T: DataInput>(key: String, as type: T.Type = T.self) -> T? {
        getDataItem(key: key)?.get()
    }

    /// - returns: The value at the given key after having been converted by the `DataItemConverter`.
    func getConvertible<T>(key: String, converter: any DataItemConverter<T>) -> T? {
        getDataItem(key: key)?.getConvertible(converter: converter)
    }

    /**
     * Returns the value as an Array of `DataItem` if the underlying value is an Array.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     */
    func getDataArray(key: String) -> [DataItem]? {
        getDataItem(key: key)?.getDataArray()
    }

    /**
     * Returns the value as a Dictionary of `DataItem` if the underlying value is a Dictionary.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     */
    func getDataDictionary(key: String) -> [String: DataItem]? {
        getDataItem(key: key)?.getDataDictionary()
    }

    /**
     * Returns the value at the given key as an `Array` of the (optional) given type.
     *
     * This method will follow the same principles of the `get<T: DataInput>(key:as:)` counterpart, but applies them on the individual `Array` elements.
     *
     * Supported types are:
     * - `Double`
     * - `Float`
     * - `Int`
     * - `Int64`
     * - `Bool`
     * - `String`
     * - `NSNumber`
     *
     * You can call this method without parameters if the return type can be inferred:
     *  ``` swift
     * let dataExtractor: DataItemExtractor = ...
     * let anIntArray: [Int?]? = dataExtractor.getArray(key: "someKey")
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataExtractor: DataItemExtractor = ...
     * let anIntArray = dataExtractor.getArray(key: "someKey", of: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangebely and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataExtractor: DataItemExtractor = DataObject(dictionary: ["someKey": [nsNumber]])
     * let aDoubleArray = dataExtractor.getArray(key: "someKey", of: Double.self) // [Double(1.5)]
     * let anIntArray = dataExtractor.getArray(key: "someKey", of: Int.self) // [Int(1)]
     *  ```
     */
    func getArray<T: DataInput>(key: String, of type: T.Type = T.self) -> [T?]? {
        getDataItem(key: key)?.getArray()
    }

    /**
     * Returns the value at the given key as an `Dictionary` of the (optional) given type.
     *
     * This method will follow the same principles of the `get<T: DataInput>(key:as:)` counterpart, but applies them on the individual `Dictionary` elements.
     *
     * Supported types are:
     * - `Double`
     * - `Float`
     * - `Int`
     * - `Int64`
     * - `Bool`
     * - `String`
     * - `NSNumber`
     *
     * You can call this method without parameters if the return type can be inferred:
     *  ``` swift
     * let dataExtractor: DataItemExtractor = ...
     * let anIntDictionary: [String: Int?]? = dataExtractor.getDictionary(key: "someKey")
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataExtractor: DataItemExtractor = ...
     * let anIntDictionary = dataExtractor.getDictionary(key: "someKey", of: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangebely and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataExtractor: DataItemExtractor = DataObject(dictionary: ["someKey": nsNumber])
     * let aDoubleDictionary = dataExtractor.getDictionary(key: "someKey", of: Double.self) // ["someKey": Double(1.5)]
     * let anIntDictionary = dataExtractor.getDictionary(key: "someKey", of: Int.self) // ["someKey": Int(1)]
     *  ```
     */
    func getDictionary<T: DataInput>(key: String, of type: T.Type = T.self) -> [String: T?]? {
        getDataItem(key: key)?.getDictionary()
    }
}
