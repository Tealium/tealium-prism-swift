//
//  Array+DataItem.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 02/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Array where Element == DataItem {
    private subscript(safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }

    /**
     * Returns the data at the given index in the requested type if the conversion is possible.
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
     * let dataItems: [DataItem] = [DataItem(value: 1.5)]
     * let anInt: Int? = dataItems.get(index: 0)
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataItems: [DataItem] = [DataItem(value: 1.5)]
     * let anInt = dataItems.get(index: 0, as: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataItems: [DataItem] = [DataItem(value: nsNumber)]
     * let aDouble: Double? = dataItems.get(index: 0) // Double(1.5)
     * let anInt: Int? = dataItems.get(index: 0) // Int(1)
     *  ```
     */
    func get<T: DataInput>(index: Index, as type: T.Type = T.self) -> T? {
        self[safe: index]?.get()
    }

    /// - returns: The value at the given index after having been converted by the `DataItemConverter`.
    func getConvertible<T>(index: Index, converter: any DataItemConverter<T>) -> T? {
        self[safe: index]?.getConvertible(converter: converter)
    }

    /**
     * Returns the value as an Array of `DataItem` if the underlying value is an Array.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     */
    func getDataArray(index: Index) -> [DataItem]? {
        self[safe: index]?.getDataArray()
    }

    /**
     * Returns the value as a Dictionary of `DataItem` if the underlying value is a Dictionary.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     */
    func getDataDictionary(index: Index) -> [String: DataItem]? {
        self[safe: index]?.getDataDictionary()
    }

    /**
     * Returns the value at the given index as an `Array` of the (optional) given type.
     *
     * This method will follow the same principles of the `get<T: DataInput>(index:as:)` counterpart, but applies them on the individual `Array` elements.
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
     * let dataItems: [DataItem] = [DataItem(value: 1.5)]
     * let anIntArray: [Int?]? = dataItems.getArray(index: 0)
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataItems: [DataItem] = [DataItem(value: 1.5)]
     * let anIntArray = dataItems.getArray(index: 0, of: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataItems: [DataItem] = [DataItem(value: nsNumber)]
     * let aDoubleArray = dataItems.getArray(index: 0, of: Double.self) // [Double(1.5)]
     * let anIntArray = dataItems.getArray(index: 0, of: Int.self) // [Int(1)]
     *  ```
     */
    func getArray<T: DataInput>(index: Index, of type: T.Type = T.self) -> [T?]? {
        self[safe: index]?.getArray()
    }

    /**
     * Returns the value at the given index as an `Dictionary` of the (optional) given type.
     *
     * This method will follow the same principles of the `get<T: DataInput>(index:as:)` counterpart, but applies them on the individual `Dictionary` elements.
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
     * let dataItems: [DataItem] = [DataItem(value: 1.5)]
     * let anIntDictionary: [String: Int?]? = dataItems.getDictionary(index: 0)
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataItems: [DataItem] = [DataItem(value: 1.5)]
     * let anIntDictionary = dataItems.getDictionary(index: 0, of: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataItems: [DataItem] = [DataItem(value: nsNumber)]
     * let aDoubleDictionary = dataItems.getDictionary(index: 0, of: Double.self) // ["someKey": Double(1.5)]
     * let anIntDictionary = dataItems.getDictionary(index: 0, of: Int.self) // ["someKey": Int(1)]
     *  ```
     */
    func getDictionary<T: DataInput>(index: Index, of type: T.Type = T.self) -> [String: T?]? {
        self[safe: index]?.getDictionary()
    }
}
