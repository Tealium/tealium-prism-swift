//
//  DataLayer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

/**
 * A storage where the application can insert some data to be added to each tracking call.
 *
 * You can potentially also extract data that was previously added via various getters.
 * If you want to add several read and writes in a transaction, you can use `transactionally`
 * and execute the transaction synchronously via the provided `DataStoreTransaction`, which also offers
 * all the typed getters of `DataItemExtractor`.
 *
 * - Warning: All the blocks passed in this protocol's methods will always be run on a Tealium queue.
 */
public protocol DataLayer {

    // MARK: - Type aliases

    /**
     * A block that receives a `DataStoreTransaction` to perform synchronous operations on the `DataLayer` in a transaction.
     *
     * - Warning: This block will always be run on a Tealium queue.
     *
     * - Parameter transaction: The `DataStoreTransaction` used to write to (`apply`, `put`, `putAll`, `remove`, `clear`), read from (`getDataItem` and all the other `DataItemExtractor` getters) and `commit` the changes to the data layer. It is only valid for the duration of the block and cannot be copied, stored, or captured by an escaping closure.
     */
    typealias TransactionBlock = (_ transaction: borrowing DataStoreTransaction) throws -> Void

    // MARK: - Inserts

    /**
     * Allows editing of the `DataLayer` using a `TransactionBlock` that receives a `DataStoreTransaction` to
     * write (`apply`, `put`, `putAll`, `remove`, `clear`), read from the data layer and finally `commit` the changes
     * in the end, all in a synchronous way.
     *
     * Since `DataStoreTransaction` conforms to `DataItemExtractor`, all the typed getters of that protocol, such as `get(key:as:)`
     * or `getArray(key:of:)`, are available on the transaction on top of `getDataItem(key:)`.
     *
     * The `DataLayer` will not be changed until the transaction is committed.
     * Writing after commit does nothing.
     * Applied, but not committed, edits won't be reflected in the items returned by the getters.
     * Committing more than once does nothing.
     *
     * - Warning: The block will always be run on a Tealium queue.
     *
     * Usage example:
     * ```swift
     * teal.dataLayer.transactionally { transaction in
     *   transaction.put(key: "key1", value: "value", expiry: .forever)
     *   transaction.apply(.put(key: "key2", value: "value2", expiry: .untilRestart))
     *   transaction.remove(key: "key3")
     *   if let count = transaction.get(key: "key4", as: Int.self) {
     *       transaction.put(key: "key4", value: count + 1, expiry: .forever)
     *   }
     *   do {
     *       try transaction.commit()
     *   } catch {
     *       print(error)
     *   }
     * }
     * ```
     *
     * - returns: A Single which can be used to subscribe a block of code to receive any errors that occur
     */
    @discardableResult
    func transactionally(execute block: @escaping TransactionBlock) -> SingleResult<Void, ModuleError<Error>>

    /**
     * Adds all key-value pairs from the `DataObject` into the storage.
     *
     * - Parameters:
     *      - dataObject: A `DataObject` containing the key-value pairs to be stored.
     *      - expiry: The time frame for this data to remain stored.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func putAll(dataObject: DataObject, expiry: Expiry) -> SingleResult<Void, ModuleError<Error>>

    /**
     * Adds a single key-value pair into the `DataLayer`.
     *
     * - Parameters:
     *      - key: The key to store the value under.
     *      - value: The `DataInput` to be stored.
     *      - expiry: The time frame for this data to remain stored.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func put(key: String, value: DataInput, expiry: Expiry) -> SingleResult<Void, ModuleError<Error>>

    // MARK: - Getters

    /**
     * Gets a `DataItem` from the `DataLayer`.
     *
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key used to look for the `DataItem`.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with `DataItem` or the eventual error in case of failure.
     */
    func getDataItem(key: String) -> SingleResult<DataItem?, ModuleError<Error>>

    /**
     * Gets a `DataObject` containing all data stored in the `DataLayer`.
     *
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Returns: A `Single` onto which you can subscribe to receive the completion with `DataObject` or the eventual error in case of failure.
     */
    func getAll() -> SingleResult<DataObject, ModuleError<Error>>

    // MARK: - Deletions

    /**
     * Removes and individual key from the `DataLayer`.
     *
     * - parameter key: The key to remove from storage.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func remove(key: String) -> SingleResult<Void, ModuleError<Error>>
    /**
     * Removes multiple keys from the `DataLayer`.
     *
     * - parameter keys: The list of keys to remove from storage.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func remove(keys: [String]) -> SingleResult<Void, ModuleError<Error>>
    /**
     * Clears all entries from the `DataLayer`.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func clear() -> SingleResult<Void, ModuleError<Error>>

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

    // MARK: - Utility Getters
    /**
     * Returns the data, in the completion block, at the given key if the conversion is possible to the requested type .
     *
     * Supported types are:
     * - `Double`
     * - `Float`
     * - `Int`
     * - `Int64`
     * - `Decimal`
     * - `Bool`
     * - `String`
     * - `NSNumber`
     *
     * The type must be specified as a parameter:
     *  ``` swift
     * let dataLayer: DataLayer = ...
     * dataLayer.get(key: "someKey", as: Int.self).onSuccess { anInt in
     *
     * }
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataLayer: DataLayer
     * dataLayer.put("someKey", nsNumber)
     * dataLayer.get("someKey", as: Double.self).onSuccess { aDouble in
     *  // Double(1.5)
     * }
     * dataLayer.get(key: "someKey", as: Int.self).onSuccess { anInt in
     *  // Int(1)
     * }
     *  ```
     *
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     *      - type: The type to convert the item into. Can be omitted if it's inferred in the completion block.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the `DataInput` or the eventual error in case of failure.
     */
    func get<T: DataInput>(key: String, as type: T.Type) -> SingleResult<T?, ModuleError<Error>>
    /**
     * Returns the value at the given `key`, after converting it via the converter, in the completion block.
     *
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     *      - converter: The `DataItemConverter` used to convert the item, if found.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the converted item or the eventual error in case of failure.
     */
    func getConvertible<T>(key: String, converter: any DataItemConverter<T>) -> SingleResult<T?, ModuleError<Error>>

    /**
     * Returns the value as an Array of `DataItem` if the underlying value is an Array, in the completion block.
     *
     * - Warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the `DataItem` array or the eventual error in case of failure.
     */
    func getDataArray(key: String) -> SingleResult<[DataItem]?, ModuleError<Error>>

    /**
     * Returns the value as a Dictionary of `DataItem` if the underlying value is a Dictionary, in the completion block.
     *
     * - Warning: Do not cast the return object as any cast will likely fail. Use the appropriate methods to extract value from a `DataItem`.
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the `DataItem` dictionary or the eventual error in case of failure.
     */
    func getDataDictionary(key: String) -> SingleResult<[String: DataItem]?, ModuleError<Error>>

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
     * - `Decimal`
     * - `Bool`
     * - `String`
     * - `NSNumber`
     *
     * The type must be specified as a parameter:
     *  ``` swift
     * let dataLayer: DataLayer = ...
     * dataLayer.getArray(key: "someKey", of: Int.self).onSuccess { anIntArray in
     *
     * }
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `Decimal`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataLayer: DataLayer
     * dataLayer.getArray(key: "someKey", of: Double.self).onSuccess { aDoubleArray in
     *  // [Double(1.5)]
     * }
     * dataLayer.getArray(key: "someKey", of: Int.self).onSuccess { anIntArray in
     *  // [Int(1)]
     * }
     *  ```
     * - Warning: The completion will always be run on a Tealium queue.
     *
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     *      - type: The type of elements contained in the Array. Can be omitted if it's inferred in the completion block.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the array of items or the eventual error in case of failure.
     */
    func getArray<T: DataInput>(key: String, of type: T.Type) -> SingleResult<[T?]?, ModuleError<Error>>

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
     * - `Decimal`
     * - `Bool`
     * - `String`
     * - `NSNumber`
     *
     * The type must be specified as a parameter:
     *  ``` swift
     * let dataLayer: DataLayer = ...
     * dataLayer.getDictionary(key: "someKey", of: Int.self).onSuccess { anIntDictionary in
     *
     * }
     *  ```
     *
     *  Every numeric type (`Int`, `Int64`, `Float`, `Double`, `Decimal`, `NSNumber`) can be used interchangeably and the conversion will be made following `NSNumber` conversion methods.
     *  ```swift
     * let nsNumber = NSNumber(1.5)
     * let dataLayer: DataLater
     * dataLayer.getDictionary(key: "someKey", of: Double.self).onSuccess { aDoubleDictionary in
     *  // ["someKey": Double(1.5)]
     * }
     * dataLayer.getDictionary(key: "someKey", of: Int.self).onSuccess { anIntDictionary in
     *  // ["someKey": Int(1)]
     * }
     *  ```
     * - Warning: The completion will always be run on a Tealium queue.
     * - Parameters:
     *      - key: The key in which to look for the convertible item.
     *      - type: The type of the values in the `Dictionary`. Can be omitted if it's inferred in the completion block.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the dictionary of items or the eventual error in case of failure.
     */
    func getDictionary<T: DataInput>(key: String, of type: T.Type) -> SingleResult<[String: T?]?, ModuleError<Error>>
}

// MARK: - Utility Extension

public extension DataLayer {

    /**
     * Adds all key-value pairs from the `DataObject` into the storage.
     *
     * Expiration is `forever` by default.
     *
     * - Parameters:
     *      - dataObject: A `DataObject` containing the key-value pairs to be stored.
     */
    @discardableResult
    func putAll(dataObject: DataObject) -> SingleResult<Void, ModuleError<Error>> {
        self.putAll(dataObject: dataObject, expiry: .forever)
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
    @discardableResult
    func put(key: String, value: DataInput) -> SingleResult<Void, ModuleError<Error>> {
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
    @discardableResult
    func put(key: String, converting convertible: DataInputConvertible, expiry: Expiry) -> SingleResult<Void, ModuleError<Error>> {
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
    @discardableResult
    func put(key: String, converting convertible: DataInputConvertible) -> SingleResult<Void, ModuleError<Error>> {
        self.put(key: key, converting: convertible, expiry: .forever)
    }
}
