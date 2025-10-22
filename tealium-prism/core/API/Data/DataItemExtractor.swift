//
//  DataItemExtractor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 02/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A container of key-value pairs that can return a `DataItem` for a given `String` key.
public protocol DataItemExtractor {
    /**
     * Returns the `DataItem` at the given key, if it was there; otherwise `nil`.
     *
     * - parameter key: The key at which to look for the `DataItem`.
     * - returns: A `DataItem` if one can be found for the given key.
     */
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
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataExtractor: DataItemExtractor = DataObject(dictionary: ["someKey": nsNumber])
     * let aDouble: Double? = dataExtractor.get(key: "someKey") // Double(1.5)
     * let anInt: Int? = dataExtractor.get(key: "someKey") // Int(1)
     *  ```
     *
     * - parameters:
     *      - key: The key at which to look for the item.
     *      - type: The expected type of the item.
     * - returns: The value at the given key if it was found and if it was of the correct type.
     */
    func get<T: DataInput>(key: String, as type: T.Type = T.self) -> T? {
        getDataItem(key: key)?.get()
    }

    /**
     * Gets and converts the item at the given key using the given converter.
     *
     * - parameters:
     *      - key: The key at which to look for the item.
     *      - converter: The converter used to convert the item to the expected type.
     * - returns: The value at the given key after having been converted by the `DataItemConverter`.
     */
    func getConvertible<T>(key: String, converter: any DataItemConverter<T>) -> T? {
        getDataItem(key: key)?.getConvertible(converter: converter)
    }

    /**
     * Returns the value as an Array of `DataItem`s if the underlying value is an Array.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     *
     * - parameters:
     *      - key: The key at which to look for the array.
     * - returns: The array of `DataItem`s, if an array is found at the given key.
     */
    func getDataArray(key: String) -> [DataItem]? {
        getDataItem(key: key)?.getDataArray()
    }

    /**
     * Returns the value as a Dictionary of `DataItem`s if the underlying value is a Dictionary.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     *
     * - parameters:
     *      - key: The key at which to look for the dictionary.
     * - returns: The dictionary of `DataItem`s, if a dictionary is found at the given key.
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
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataExtractor: DataItemExtractor = DataObject(dictionary: ["someKey": [nsNumber]])
     * let aDoubleArray = dataExtractor.getArray(key: "someKey", of: Double.self) // [Double(1.5)]
     * let anIntArray = dataExtractor.getArray(key: "someKey", of: Int.self) // [Int(1)]
     *  ```
     *
     * - parameters:
     *      - key: The key at which to look for the array.
     *      - type: The expected type of each item of the array.
     * - returns: The array of items of optional type at the given key if it was found. Each item will be `nil` if they were of the wrong type.
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
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataExtractor: DataItemExtractor = DataObject(dictionary: ["someKey": nsNumber])
     * let aDoubleDictionary = dataExtractor.getDictionary(key: "someKey", of: Double.self) // ["someKey": Double(1.5)]
     * let anIntDictionary = dataExtractor.getDictionary(key: "someKey", of: Int.self) // ["someKey": Int(1)]
     *  ```
     *
     * - parameters:
     *      - key: The key at which to look for the dictionary.
     *      - type: The expected type of each item of the dictionary.
     * - returns: The dictionary of items of optional type at the given key if it was found. Each item will be `nil` if they were of the wrong type.
     */
    func getDictionary<T: DataInput>(key: String, of type: T.Type = T.self) -> [String: T?]? {
        getDataItem(key: key)?.getDictionary()
    }

    /**
     * Extracts a nested `DataItem` according to the given `JSONPath`.
     *
     * This is equivalent to `getDataItem(key:)`, except it can search for nested values inside dictionaries and arrays by using a `JSONPath`.
     *
     * If any components of the `JSONPath` is not found in this `DataItemExtractor` or if they are of the wrong type,
     * `nil` will be returned.
     *
     * As an example, in the following snippet:
     * ```swift
     * let object = DataObject(dictionary: [
     *   "root": [
     *      "item"
     *   ]
     * ])
     * let result = object.extractDataItem(path: JSONPath("root")[0])
     * ```
     * The result would be a `DataItem` containing the string "item".
     *
     *
     * - Parameters:
     *      - path: The `JSONPath` describing the path to a potentially nested item.
     * - Returns: The required `DataItem` if found; else `nil`.
     */
    func extractDataItem(path: JSONPath) -> DataItem? {
        extract(path.head)
    }

    /**
     * Returns the data at the given path in the requested type if the conversion is possible.
     *
     * This is equivalent to `get(key:as:)`, except it can search for nested values inside dictionaries and arrays by using a `JSONPath`.
     *
     * As an example, in the following snippet:
     * ```swift
     * let object = DataObject(dictionary: [
     *   "root": [
     *      "item"
     *   ]
     * ])
     * let result = object.extract(path: JSONPath("root")[0], as: String.self)
     * ```
     * The result would be the string "item".
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
     * let anInt: Int? = dataExtractor.extract(path: JSONPath("someKey"))
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataExtractor: DataItemExtractor = ...
     * let anInt = dataExtractor.extract(path: JSONPath("someKey"), as: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataExtractor: DataItemExtractor = DataObject(dictionary: ["someKey": nsNumber])
     * let aDouble: Double? = dataExtractor.extract(path: JSONPath("someKey")) // Double(1.5)
     * let anInt: Int? = dataExtractor.extract(path: JSONPath("someKey")) // Int(1)
     *  ```
     *
     * - parameters:
     *      - path: The path at which to look for the item.
     *      - type: The expected type of the item.
     * - returns: The value at the given path if it was found and if it was of the correct type.
     */
    func extract<T: DataInput>(path: JSONPath, as type: T.Type = T.self) -> T? {
        extractDataItem(path: path)?.get()
    }

    /**
     * Gets and converts the item at the given path using the given converter.
     *
     * This is equivalent to `getConvertible(key:converter:)`, except it can search for nested values inside dictionaries and arrays by using a `JSONPath`.
     *
     * - parameters:
     *      - path: The path at which to look for the item.
     *      - converter: The converter used to convert the item to the expected type.
     * - returns: The value at the given path after having been converted by the `DataItemConverter`.
     */
    func extractConvertible<T>(path: JSONPath, converter: any DataItemConverter<T>) -> T? {
        extractDataItem(path: path)?.getConvertible(converter: converter)
    }

    /**
     * Returns the value as an Array of `DataItem`s if the underlying value is an Array.
     *
     * This is equivalent to `getDataArray(key:)`, except it can search for nested values inside dictionaries and arrays by using a `JSONPath`.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     *
     *
     * - parameters:
     *      - path: The path at which to look for the array.
     * - returns: The array of `DataItem`s, if an array is found at the given path.
     */
    func extractDataArray(path: JSONPath) -> [DataItem]? {
        extractDataItem(path: path)?.getDataArray()
    }

    /**
     * Returns the value as a Dictionary of `DataItem`s if the underlying value is a Dictionary.
     *
     * This is equivalent to `getDataDictionary(key:)`, except it can search for nested values inside dictionaries and arrays by using a `JSONPath`.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     *
     * - parameters:
     *      - path: The path at which to look for the dictionary.
     * - returns: The dictionary of `DataItem`s, if a dictionary is found at the given path.
     */
    func extractDataDictionary(path: JSONPath) -> [String: DataItem]? {
        extractDataItem(path: path)?.getDataDictionary()
    }

    /**
     * Returns the value at the given path as an `Array` of the (optional) given type.
     *
     * This is equivalent to `getArray(key:of:)`, except it can search for nested values inside dictionaries and arrays by using a `JSONPath`.
     *
     * This method will follow the same principles of the `extract<T: DataInput>(path:as:)` counterpart, but applies them on the individual `Array` elements.
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
     * let anIntArray: [Int?]? = dataExtractor.extractArray(path: JSONPath("someKey"))
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataExtractor: DataItemExtractor = ...
     * let anIntArray = dataExtractor.extractArray(path: JSONPath("someKey"), of: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataExtractor: DataItemExtractor = DataObject(dictionary: ["someKey": [nsNumber]])
     * let aDoubleArray = dataExtractor.extractArray(path: JSONPath("someKey"), of: Double.self) // [Double(1.5)]
     * let anIntArray = dataExtractor.extractArray(path: JSONPath("someKey"), of: Int.self) // [Int(1)]
     *  ```
     *
     * - parameters:
     *      - path: The path at which to look for the array.
     *      - type: The expected type of each item of the array is expected to be.
     * - returns: The array of items of optional type at the given path if it was found. Each item will be `nil` if they were of the wrong type.
     */
    func extractArray<T: DataInput>(path: JSONPath, of type: T.Type = T.self) -> [T?]? {
        extractDataItem(path: path)?.getArray()
    }

    /**
     * Returns the value at the given path as a `Dictionary` of the (optional) given type.
     *
     * This is equivalent to `getDictionary(key:of:)`, except it can search for nested values inside dictionaries and arrays by using a `JSONPath`.
     *
     * This method will follow the same principles of the `extract<T: DataInput>(path:as:)` counterpart, but applies them on the individual `Dictionary` elements.
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
     * let anIntDictionary: [String: Int?]? = dataExtractor.extractDictionary(path: JSONPath("someKey"))
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataExtractor: DataItemExtractor = ...
     * let anIntDictionary = dataExtractor.extractDictionary(path: JSONPath("someKey"), of: Int.self)
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataExtractor: DataItemExtractor = DataObject(dictionary: ["someKey": nsNumber])
     * let aDoubleDictionary = dataExtractor.extractDictionary(path: JSONPath("someKey"), of: Double.self) // ["someKey": Double(1.5)]
     * let anIntDictionary = dataExtractor.extractDictionary(path: JSONPath("someKey"), of: Int.self) // ["someKey": Int(1)]
     *  ```
     *
     * - parameters:
     *      - path: The path at which to look for the dictionary.
     *      - type: The expected type of each item of the dictionary.
     * - returns: The dictionary of items of optional type at the given path if it was found. Each item will be `nil` if they were of the wrong type.
     */
    func extractDictionary<T: DataInput>(path: JSONPath, of type: T.Type = T.self) -> [String: T?]? {
        extractDataItem(path: path)?.getDictionary()
    }

    fileprivate func extract(_ component: JSONPathComponent) -> DataItem? {
        guard case let .key(key, next) = component else {
            return nil
        }
        let item = getDataItem(key: key)
        return item?.extract(next)
    }
}

fileprivate extension Array where Element == DataItem {
    func extract(_ component: JSONPathComponent) -> DataItem? {
        guard case let .index(index, next) = component else {
            return nil
        }
        let item = self[safe: index]
        return item?.extract(next)
    }
}

fileprivate extension DataItem {
    func extract(_ component: JSONPathComponent?) -> DataItem? {
        guard let component else {
            return self
        }
        if let dictionary = getDataDictionary() {
            return dictionary.extract(component)
        } else if let array = getDataArray() {
            return array.extract(component)
        } else {
            return nil
        }
    }
}
