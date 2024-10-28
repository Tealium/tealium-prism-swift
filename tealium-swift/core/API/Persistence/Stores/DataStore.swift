//
//  DataStore.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Generic data storage for storing `DataInput` and retrieving `DataItem` objects.
 *
 * Implementations are not guaranteed to be persistent. For instance, in cases where there may be
 * insufficient storage space on the device, or other reasons such as write permissions etc.
 *
 * Stored data requires an `Expiry` to be provided when storing, and expired data will not be
 * included in any retrieval operations; that is, expired data won't be returned by `get` or `getAll`
 * but it will also not be included in any aggregate methods such as `keys` or `count`.
 */
public protocol DataStore: AnyObject, DataItemExtractor {
    /**
     * Returns a `DataStoreEditor` able to mutate the data in this storage.
     *
     * - returns: `DataStoreEditor` to update the stored data.
     */
    func edit() -> DataStoreEditor

    /**
     * Gets a dictionary containing all data stored.
     *
     * - returns: A `DataObject` dictionary with all the data contained in the storage.
     */
    func getAll() -> DataObject

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
    var onDataUpdated: Observable<DataObject> { get }

    /**
     * Observable of key-value pairs from this DataStore that have been removed or expired
     *
     * Note that expiration may not happen immediately when the value is expired but may happen asynchronously on a later check
     */
    var onDataRemoved: Observable<[String]> { get }
}

/// Enables editing multiple entries in the module storage in a transactional way.
public protocol DataStoreEditor {
    /**
     * Adds a single key-value pair into the storage.
     *
     * - parameter key: The key to store the value under.
     * - parameter value: The `DataInput` to be stored.
     * - parameter expiry: The time frame for this data to remain stored.
     *
     * - returns: the same `DataStoreEditor` to continue editing this storage.
     */
    func put(key: String, value: DataInput, expiry: Expiry) -> Self

    /**
     * Adds all key-value pairs from the dictionary into the storage.
     *
     * - parameter dataObject: A `DataObject` containing the key-value pairs to be stored.
     * - parameter expiry: The time frame for this data to remain stored.
     *
     * - returns: the same `DataStoreEditor` to continue editing this storage.
     */
    func putAll(dataObject: DataObject, expiry: Expiry) -> Self

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
