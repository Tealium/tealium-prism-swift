//
//  KeyValueRepository.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Generic storage repository for reading and writing key-value pairs of data.
 *
 * Implementations are expected to not return Expired data based on the `Expiry` provided to any
 * methods that require it. This should be consistent across all methods; i.e. `keys` should not
 * return a list containing entries that are expired.
 *
 * Calls to the editing methods (`upsert`/`remove`/`clear`) are expected to persist immediately -
 * where multiple data updates are required to be transactional, then `transactionally` should be
 * used.
 */
protocol KeyValueRepository {
    /// Runs all methods in a transaction
    func transactionally(_ block: (Self) throws -> Void) throws

    /**
     * Fetch and item given its key.
     *
     * - parameter key: The key to use to lookup the value.
     *
     * - returns: The `TealiumDataOutput` for the given key, else nil.
     */
    func get(key: String) -> TealiumDataOutput?

    /**
     * Fetch all items in the repository.
     *
     * - returns: The `[String: TealiumDataOutput]` dictionary with all the stored key-values in the repository.
     */
    func getAll() -> [String: TealiumDataOutput]

    /**
     * Removes and item from storage given the key.
     *
     * - parameter key: The storage key to remove.
     *
     * - returns: Then number of rows removed.
     */
    func delete(key: String) throws -> Int

    /**
     * Inserts a new item or updates a preexisting one.
     *
     * - Parameters:
     *  - key: The key to be updated.
     *  - value: The value insert or replace.
     *  - expiry: The expiry to update.
     *
     * - returns: The id of the newly added data
     */
    @discardableResult
    func upsert(key: String, value: TealiumDataInput, expiry: Expiry) throws -> Int64

    /**
     * Removes all entries fromt he storage.
     *
     * - returns: Then number of rows removed.
     */
    func clear() throws -> Int

    /// Returns a list of keys for all entries in the repository.
    func keys() -> [String]

    /// Returns the count of entries in the repository.
    func count() -> Int

    /// Returns true if an item with the given key is present in the repository.
    func contains(key: String) -> Bool

    /// Returns the `Expiry` for the given key if it exists and is not expired.
    func getExpiry(key: String) -> Expiry?
}
