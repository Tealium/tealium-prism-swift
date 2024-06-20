//
//  DataStore.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Generic data storage for storing `TealiumDataInput` and retrieving `TealiumDataOutput` objects.
 *
 * Implementations are not guaranteed to be persistent. For instance, in cases where there may be
 * insufficient storage space on the device, or other reasons such as write permissions etc.
 *
 * Stored data requires an `Expiry` to be provided when storing, and expired data will not be
 * included in any retrieval operations; that is, expired data won't be returned by `get` or `getAll`
 * but it will also not be included in any aggregate methods such as `keys` or `count`.
 */
public protocol DataStore {
    /**
     * Returns a `DataStoreEditor` able to mutate the data in this storage.
     *
     * - returns: `DataStoreEditor` to update the stored data.
     */
    func edit() -> DataStoreEditor

    /**
     * Gets the `TealiumDataOutput` stored at the given key if there is one.
     *
     * - parameter key: The key for the required value.
     *
     * - returns: The `TealiumDataOutput` or nil.
     */
    func get(key: String) -> TealiumDataOutput?

    /**
     * Gets a dictionary containing all data stored.
     *
     * - returns: A `[String: TealiumDataOutput]` dictionary with all the data contained in the storage.
     */
    func getAll() -> [String: TealiumDataOutput]

    /**
     * Returns all keys stored in this DataStore
     *
     * - returns: A list of all string keys present in the DataStore
     */
    func keys() -> [String]

    /**
     * Returns the number of entries in this DataStore
     *
     * - returns: the count of all key-value pairs in the DataStore
     */
    func count() -> Int

    /// Observable of key-value pairs from this DataStore that have been updated
    var onDataUpdated: TealiumObservable<[String: TealiumDataInput]> { get }

    /**
     * Observable of key-value pairs from this DataStore that have been removed or expired
     *
     * Note that expiration may not happen immediately when the value is expired but may happen asynchronously on a later check
     */
    var onDataRemoved: TealiumObservable<[String]> { get }
}

/// Enables editing multiple entries in the module storage in a transactional way.
public protocol DataStoreEditor {
    /**
     * Adds a single key-value pair into the storage.
     *
     * - parameter key: The key to store the value under.
     * - parameter value: The `TealiumDataInput` to be stored.
     * - parameter expiry: The time frame for this data to remain stored.
     *
     * - returns: the same `DataStoreEditor` to continue editing this storage.
     */
    func put(key: String, value: TealiumDataInput, expiry: Expiry) -> Self

    /**
     * Adds all key-value pairs from the dictionary into the storage.
     *
     * - parameter dictionary: A `TealiumDictionaryInput` containing the key-value pairs to be stored.
     * - parameter expiry: The time frame for this data to remain stored.
     *
     * - returns: the same `DataStoreEditor` to continue editing this storage.
     */
    func putAll(dictionary: TealiumDictionaryInput, expiry: Expiry) -> Self

    /**
     * Removes and individual key from storage.
     *
     * - parameter key: the key to remove from storage.
     *
     * - returns: the same `DataStoreEditor` to continue editing this storage.
     */
    func remove(key: String) -> Self

    /**
     * Removes multiple keys from storage.
     *
     * - parameter keys: the list of keys to remove from storage.
     *
     * - returns: the same `DataStoreEditor` to continue editing this storage.
     */
    func remove(keys: [String]) -> Self

    /**
     * Clears all entries from storage before then adding any key-value pairs.
     *
     * - returns: the same `DataStoreEditor` to continue editing this storage.
     */
    func clear() -> Self

    /**
     * Writes the updates to disk in a transaction.
     *
     * Calling this method multiple times is not supported, and subsequent executions
     * are ignored.
     */
    func commit() throws
}

public extension DataStore {
    /**
     * Returns the `NSNumber` stored at the given key if present and if it is the correct type.
     *
     * - Parameters:
     *  - key: The key from which to extract the number.
     *
     *  - Returns: The `NSNumber` stored at that key, if present and if it is the correct type.
     */
    func getNSNumber(key: String) -> NSNumber? {
        get(key: key)?.getNSNumber()
    }

    /**
     * Returns the `Int64` stored at the given key if present and if it is the correct type.
     *
     * Any `NSNumber` convertible data will be read as such and then converted to `Int64`.
     *
     * - Parameters:
     *  - key: The key from which to extract the number.
     *
     *  - Returns: The `Int64` stored at that key, if present and if it is the correct type.
     */
    func getInt(key: String) -> Int64? {
        get(key: key)?.getInt()
    }

    /**
     * Returns the `Double` stored at the given key if present and if it is the correct type.
     *
     * Any `NSNumber` convertible data will be read as such and then converted to `Double`.
     *
     * - Parameters:
     *  - key: The key from which to extract the number.
     *
     *  - Returns: The `Double` stored at that key, if present and if it is the correct type.
     */
    func getDouble(key: String) -> Double? {
        get(key: key)?.getDouble()
    }

    /**
     * Returns the `Bool` stored at the given key if present and if it is the correct type.
     *
     * Any `NSNumber` convertible data will be read as such and then converted to `Bool`.
     *
     * - Parameters:
     *  - key: The key from which to extract the number.
     *
     *  - Returns: The `Bool` stored at that key, if present and if it is the correct type.
     */
    func getBool(key: String) -> Bool? {
        get(key: key)?.getBool()
    }

    /**
     * Returns the `String` stored at the given key if present and if it is the correct type.
     *
     * - Parameters:
     *  - key: The key from which to extract the `String`.
     *
     *  - Returns: The `String` stored at that key, if present and if it is the correct type.
     */
    func getString(key: String) -> String? {
        get(key: key)?.getString()
    }

    /**
     * Returns the `Array` stored at the given key if present and if it is the correct type.
     *
     * - Parameters:
     *  - key: The key from which to extract the `Array`.
     *
     *  - Returns: The `Array` stored at that key, if present and if it is the correct type.
     */
    func getArray(key: String) -> [TealiumDataOutput]? {
        get(key: key)?.getArray()
    }

    /**
     * Returns the `Dictionary` stored at the given key if present and if it is the correct type.
     *
     * - Parameters:
     *  - key: The key from which to extract the `Dictionary`.
     *
     *  - Returns: The `Dictionary` stored at that key, if present and if it is the correct type.
     */
    func getDictionary(key: String) -> [String: TealiumDataOutput]? {
        get(key: key)?.getDictionary()
    }
}
