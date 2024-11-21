//
//  DataLayer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 28/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

/**
 * A storage where the application can insert some data to be added to each tracking call.
 *
 * You can potentially also extract data that was previously added via various getters.
 * If you want to add several read and writes in a transaction, you can use `transactionally`
 * and execute all the transaction with the provided synchronous blocks.
 *
 * - Warning: All the blocks passed in this protocol's methods will always be run on a Tealium queue.
 */
public protocol DataLayer {

    // MARK: - Typealiases

    /**
     * A block used to apply a `DataStoreEdit`.
     *
     * The `DataLayer` will not be changed until the transaction is committed. Applying after commit does nothing.
     *
     * - Parameter edit: The `DataStoreEdit` to be applied once the transaction is committed.
     */
    typealias Apply = (_ edit: DataStoreEdit) -> Void

    /**
     * A block to retrieve something synchronously from the `DataLayer`.
     *
     * Applied, but not committed, edits won't be reflected in the items returned by this block.
     *
     * - Parameter key: The key used to look up data in the `DataLayer`.
     * - Returns: The `DataItem` if one was found for the provided key.
     */
    typealias Get = (_ key: String) -> DataItem?

    /**
     * A block used to commit the transaction. It will commit all the edits that were previously applied.
     *
     * Committing more than once does nothing.
     *
     * - Throws: An error when the transaction fails.
     */
    typealias Commit = () throws -> Void

    /**
     * A block that offers utility synchronous methods to perform operations on the DataLayer in a transaction.
     *
     * - Warning: This block will always be run on a Tealium queue.
     *
     * - Parameters:
     *   - apply: A block that can be called to apply a `DataStoreEdit.put` or `DataStoreEdit.remove`. The `DataLayer` will not be changed until the transaction is committed. Applying after commit does nothing.
     *   - getDataItem: A block to retrieve something synchronously from the `DataLayer`. Applied, but not committed, edits won't be reflected in the items returned by this block.
     *   - commit: A block used to commit the transaction. It will commit all the edits that were previously applied. Committing more than once does nothing.
     */
    typealias TransactionBlock = (_ apply: Apply, _ getDataItem: Get, _ commit: Commit) -> Void

    // MARK: - Inserts

    /**
     * Allows editing of the `DataLayer` using a `TransactionBlock` that provides methods to
     * `Apply` edits, `Get` some `DataItem`s from the data layer and finally `Commit` the changes
     * in the end, all in a synchronous way.
     *
     * The `DataLayer` will not be changed until the transaction is committed.
     * Applying after commit does nothing.
     * Applied, but not committed, edits won't be reflected in the items returned by this block.
     * Committing more than once does nothing.
     *
     * - Warning: The block will always be run on a Tealium queue.
     *
     * Usage example:
     * ```swift
     * teal.dataLayer.transactionally { apply, getDataItem, commit in
     *   apply(.put("key1", "value", .forever))
     *   apply(.put("key2", "value2", .untilRestart))
     *   apply(.remove("key3"))
     *   if let count = getDataItem("key4")?.get(as: Int.self) {
     *       apply(.put("key4", count + 1, .forever))
     *   }
     *   do {
     *       try commit()
     *   } catch {
     *       print(error)
     *   }
     * }
     * ```
     */
    func transactionally(execute block: @escaping TransactionBlock)

    /**
     * Adds all key-value pairs from the `DataObject` into the storage.
     *
     * - Parameters:
     *      - data: A `DataObject` containing the key-value pairs to be stored.
     *      - expiry: The time frame for this data to remain stored.
     */
    func put(data: DataObject, expiry: Expiry)

    /**
     * Adds a single key-value pair into the `DataLayer`.
     *
     * - Parameters:
     *      - key: The key to store the value under.
     *      - value: The `DataInput` to be stored.
     *      - expiry: The time frame for this data to remain stored.
     */
    func put(key: String, value: DataInput, expiry: Expiry)

    // MARK: - Getters

    /**
     * Gets a `DataItem` from the `DataLayer`.
     *
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key used to look for the `DataItem`.
     *      - completion: A block called with the `DataItem` if it was present in the `DataLayer`.
     */
    func getDataItem(key: String, completion: @escaping (DataItem?) -> Void)

    /**
     * Gets a `DataObject` containing all data stored in the `DataLayer`.
     *
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - parameter completion: A block called with a `DataObject` dictionary containing all the data from the `DataLayer`.
     */
    func getAll(completion: @escaping (DataObject?) -> Void)

    // MARK: - Deletions

    /**
     * Removes and individual key from the `DataLayer`.
     *
     * - parameter key: The key to remove from storage.
     */
    func remove(key: String)
    /**
     * Removes multiple keys from the `DataLayer`.
     *
     * - parameter keys: The list of keys to remove from storage.
     */
    func remove(keys: [String])
    /**
     * Clears all entries from the `DataLayer`.
     */
    func clear()

    // MARK: - Events

    /**
     * A `Subscribable` to which you can subscribe to receive all the data that was updated in the `DataLayer`.
     *
     * - Warning: The events will always be reported on a Tealium queue.
     */
    var onDataUpdated: any Subscribable<DataObject> { get }

    /**
     * A `Subscribable` to which you can subscribe to receive all the data that was removed from the `DataLayer`.
     *
     * This `Subscribable` will receive events for both data manually removed and for data expired.
     *
     * - Warning: The events will always be reported on a Tealium queue.
     */
     var onDataRemoved: any Subscribable<[String]> { get }
}

// MARK: - Utility Extension

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
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     *      - type: The type to convert the item into. Can be omitted if it's inferred in the completion block.
     *      - completion: The completion called with the `DataItem` array at the given key, if found.
     */
    func get<T: DataInput>(key: String, as type: T.Type = T.self, completion: @escaping (T?) -> Void) {
        getDataItem(key: key) { completion($0?.get(as: type)) }
    }

    /**
     * Returns the value at the given `key`, after converting it via the converter, in the completion block.
     *
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     *      - converter: The `DataItemConverter` used to convert the item, if found.
     *      - completion: The completion called with the value at the given key after having been converted by the `DataItemConverter`.
     */
    func getConvertible<T>(key: String, converter: any DataItemConverter<T>, completion: @escaping (T?) -> Void) {
        getDataItem(key: key) { completion($0?.getConvertible(converter: converter)) }
    }

    /**
     * Returns the value as an Array of `DataItem` if the underlying value is an Array, in the completion block.
     *
     * - Warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     *      - completion: The completion called with the `DataItem` array at the given key, if found.
     */
    func getDataArray(key: String, completion: @escaping ([DataItem]?) -> Void) {
        getDataItem(key: key) { completion($0?.getDataArray()) }
    }

    /**
     * Returns the value as a Dictionary of `DataItem` if the underlying value is a Dictionary, in the completion block.
     *
     * - Warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
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
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
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
     * - Warning: The completion will always be run on a Tealium queue.
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     *      - type: The type of the values in the `Dictionary`. Can be omitted if it's inferred in the completion block.
     *      - completion: The completion called with the `DataItem` dictionary at the given key, if found.
     */
    func getDictionary<T: DataInput>(key: String, of type: T.Type = T.self, completion: @escaping ([String: T?]?) -> Void) {
        getDataItem(key: key) { completion($0?.getDictionary(of: type)) }
    }

    /**
     * Adds all key-value pairs from the `DataObject` into the storage.
     *
     * Expiration is `forever` by default.
     *
     * - Parameters:
     *      - data: A `DataObject` containing the key-value pairs to be stored.
     */
    func put(data: DataObject) {
        self.put(data: data, expiry: .forever)
    }

    /**
     * Adds a single key-value pair into the `DataLayer`.
     *
     * Expiration is `forever` by default.
     * 
     * - Parameters:
     *      - key: The key to store the value under.
     *      - value: The `DataInput` to be stored.
     */
    func put(key: String, value: DataInput) {
        self.put(key: key, value: value, expiry: .forever)
    }

    /**
     * Adds a single key-value pair into the `DataLayer`.
     *
     * - Parameters:
     *      - key: The key to store the value under.
     *      - convertible: The `DataInputConvertible` to be stored after conversion.
     *      - expiry: The time frame for this data to remain stored.
     */
    func put(key: String, converting convertible: DataInputConvertible, expiry: Expiry) {
        self.put(key: key, value: convertible.toDataInput(), expiry: expiry)
    }

    /**
     * Adds a single key-value pair into the `DataLayer`.
     *
     * Expiration is `forever` by default.
     *
     * - Parameters:
     *      - key: The key to store the value under.
     *      - convertible: The `DataInputConvertible` to be stored after conversion.
     */
    func put(key: String, converting convertible: DataInputConvertible) {
        self.put(key: key, value: convertible.toDataInput(), expiry: .forever)
    }
}
