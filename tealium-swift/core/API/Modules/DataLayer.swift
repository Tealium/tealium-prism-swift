//
//  DataLayer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 28/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

public protocol DataLayer {
    typealias Apply = (_ edit: DataStoreEdit) -> Void
    typealias Get = (_ key: String) -> DataItem?
    typealias Commit = () throws -> Void
    /**
     * A block that offers utility synchronous methods to perform operations on the DataLayer in a transaction.
     *
     * - Warning: This block will always be run on a Tealium queue.
     *
     * - Parameters:
     *   - apply: a method that can be called to apply a `DataStoreEdit.put` or `DataStoreEdit.remove`. The `DataLayer` will not be changed until the transaction is committed. Applying after commit does nothing.
     *   - getDataItem: a method to retrieve something synchronously from the `DataLayer`.
     *   - commit: a method used to commit the transaction. It will commit all the edits that were previously applied. Committing more than once does nothing.
     */
    typealias TransactionBlock = (_ apply: Apply, _ getDataItem: Get, _ commit: Commit) -> Void
    /**
     * Allows editing of the DataLayer using a `TransactionBlock` that provides methods to
     * `Apply` edits, `Get` some `DataItem`s from the data layer and finally `Commit` the changes
     * in the end, all in a synchronous way.
     */
    func transactionally(execute block: @escaping TransactionBlock)

    // Inserts
    func put(data: DataObject, expiry: Expiry)
    func put(key: String, value: DataInput, expiry: Expiry)

    // Reads
    func getDataItem(key: String, completion: @escaping (DataItem?) -> Void)
    func getAll(completion: @escaping (DataObject) -> Void)

    // Deletions
    func remove(key: String)
    func remove(keys: [String])
    func clear()

    // Events
    var onDataUpdated: any Subscribable<DataObject> { get }
    var onDataRemoved: any Subscribable<[String]> { get }
}

public extension DataLayer {
    /**
     * Returns the data, in the completion block, at the given key if the conversion is possible to the requested type .
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
     * You can call this method without the `type` parameter if the underlying type can be inferred:
     *  ``` swift
     * let dataLayer: DataLayer = ...
     * dataLayer.get(key: "someKey") { anInt in
     *  if let anInt: Int = anInt {
     *  }
     * }
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataLayer: DataLayer = ...
     * dataLayer.get(key: "someKey", as: Int.self) { anInt in
     *
     * }
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataLayer: DataLayer
     * dataLayer.put("someKey", nsNumber)
     * dataLayer.get("someKey", as: Double.self) { aDouble in
     *  // Double(1.5)
     * }
     * dataLayer.get(key: "someKey", as: Int.self) { anInt in
     *  // Int(1)
     * }
     *  ```
     *
     * - Parameters:
     *      - key: The key in wich to look for the convertible item.
     *      - type: The type to convert the item into. Can be omitted if it's inferred in the completion block.
     *      - completion: The completion called with the `DataItem` array at the given key, if found.
     */
    func get<T: DataInput>(key: String, as type: T.Type = T.self, completion: @escaping (T?) -> Void) {
        getDataItem(key: key) { completion($0?.get(as: type)) }
    }

    /**
     * Returns the value at the given `key`, after converting it via the converter, in the completion block.
     *
     * - Parameters:
     *      - key: The key in wich to look for the convertible item.
     *      - converter: The `DataItemConverter` used to convert the item, if found.
     *      - completion: The completion called with the value at the given key after having been converted by the `DataItemConverter`.
     */
    func getConvertible<T>(key: String, converter: any DataItemConverter<T>, completion: @escaping (T?) -> Void) {
        getDataItem(key: key) { completion($0?.getConvertible(converter: converter)) }
    }

    /**
     * Returns the value as an Array of `DataItem` if the underlying value is an Array, in the completion block.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     *
     * - Parameters:
     *      - key: The key in wich to look for the convertible item.
     *      - completion: The completion called with the `DataItem` array at the given key, if found.
     */
    func getDataArray(key: String, completion: @escaping ([DataItem]?) -> Void) {
        getDataItem(key: key) { completion($0?.getDataArray()) }
    }

    /**
     * Returns the value as a Dictionary of `DataItem` if the underlying value is a Dictionary, in the completion block.
     *
     * - warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     *
     * - Parameters:
     *      - key: The key in wich to look for the convertible item.
     *      - completion: The completion called with the `DataItem` dictionary at the given key, if found.
     */
    func getDataDictionary(key: String, completion: @escaping ([String: DataItem]?) -> Void) {
        getDataItem(key: key) { completion($0?.getDataDictionary()) }
    }

    /**
     * Returns the value at the given key as an `Array` of the (optional) given type, in the completion block.
     *
     * This method will follow the same principles of the `get<T: DataInput>(key:as:completion:)` counterpart, but applies them on the individual `Array` elements.
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
     * You can call this method without the `type` parameter if the underlying type can be inferred:
     *  ``` swift
     * let dataLayer: DataLayer = ...
     * dataLayer.getArray(key: "someKey") { anIntArray in
     *  if let intArray: [Int?] = anIntArray {
     *
     *  }
     * }
     *
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataLayer: DataLayer = ...
     * dataLayer.getArray(key: "someKey", of: Int.self) { anIntArray in
     *
     * }
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataLayer: DataLayer
     * dataLayer.getArray(key: "someKey", of: Double.self) { aDoubleArray in
     *  // [Double(1.5)]
     * }
     * dataLayer.getArray(key: "someKey", of: Int.self) { anIntArray in
     *  // [Int(1)]
     * }
     *  ```
     *
     * - Parameters:
     *      - key: The key in wich to look for the convertible item.
     *      - type: The type of elements contained in the Array. Can be omitted if it's inferred in the completion block.
     *      - completion: The completion called with the `DataItem` array at the given key, if found.
     */
    func getArray<T: DataInput>(key: String, of type: T.Type = T.self, completion: @escaping ([T?]?) -> Void) {
        getDataItem(key: key) { completion($0?.getArray(of: type)) }
    }

    /**
     * Returns the value at the given key as a `Dictionary` of the (optional) given type, in the completion block.
     *
     * This method will follow the same principles of the `get<T: DataInput>(key:as:completion:)` counterpart, but applies them on the individual `Dictionary` elements.
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
     * You can call this method without the `type` parameter if the underlying type can be inferred:
     *  ``` swift
     * let dataLayer: DataLayer = ...
     * dataLayer.getDictionary(key: "someKey") { anIntDictionary in
     *    if let intDictionary: [String: Int?] = anIntDictionary {
     *
     *    }
     * }
     *  ```
     * Alternatively the type must be specified as a parameter:
     *  ``` swift
     * let dataLayer: DataLayer = ...
     * dataLayer.getDictionary(key: "someKey", of: Int.self) { anIntDictionary in
     *
     * }
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataLayer: DataLater
     * dataLayer.getDictionary(key: "someKey", of: Double.self) { aDoubleDictionary in
     *  // ["someKey": Double(1.5)]
     * }
     * dataLayer.getDictionary(key: "someKey", of: Int.self) { anIntDictionary in
     *  // ["someKey": Int(1)]
     * }
     *  ```
     *
     * - Parameters:
     *      - key: The key in wich to look for the convertible item.
     *      - type: The type of the values in the `Dictionary`. Can be omitted if it's inferred in the completion block.
     *      - completion: The completion called with the `DataItem` dictionary at the given key, if found.
     */
    func getDictionary<T: DataInput>(key: String, of type: T.Type = T.self, completion: @escaping ([String: T?]?) -> Void) {
        getDataItem(key: key) { completion($0?.getDictionary(of: type)) }
    }
}
