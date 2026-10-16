//
//  DataStoreTransaction.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 18/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK: - Transaction Editor

/**
 * A `DataStoreTransaction`, a `~Copyable` struct passed `borrowing` to a `DataLayer.TransactionBlock` given to `DataLayer.transactionally(execute:)`.
 *
 * It wraps a pending `DataStore` edit session, offering the write helpers (`apply`, `put`, `putAll`, `remove`, `clear`) and `commit` as synchronous methods.
 *
 * It conforms to `DataItemExtractor`, so all the typed getters of that protocol (`get(key:as:)`, `getArray(key:of:)`, …) and of
 * `JSONPathExtractable` (`extract(path:as:)`, …) are available directly on the transaction, on top of the `getDataItem(key:)` read requirement.
 *
 * - Note: `DataStoreTransaction` is noncopyable and is passed `borrowing` to the `TransactionBlock`, so it cannot be
 *   copied, stored in a property, or captured by an escaping closure. It is only valid for the duration of the block.
 */
public struct DataStoreTransaction: ~Copyable, DataItemExtractor {
    private let dataStore: any DataStore
    private let editor: DataStoreEditor

    init(dataStore: any DataStore) {
        self.dataStore = dataStore
        self.editor = dataStore.edit()
    }

    /**
     * Applies an edit (`DataStoreEdit.put` or `DataStoreEdit.remove`) to the pending transaction.
     *
     * The `DataLayer` will not be changed until the transaction is committed. Applying after commit does nothing.
     *
     * - Parameter edit: The `DataStoreEdit` to be applied once the transaction is committed.
     */
    public func apply(_ edit: DataStoreEdit) {
        _ = editor.apply(edit: edit)
    }

    /**
     * Adds a single key-value pair to the pending transaction.
     *
     * The `DataLayer` will not be changed until the transaction is committed. Putting after commit does nothing.
     *
     * - Parameters:
     *      - key: The key to store the value under.
     *      - value: The `DataInput` to be stored.
     *      - expiry: The time frame for this data to remain stored.
     */
    public func put(key: String, value: DataInput, expiry: Expiry) {
        _ = editor.put(key: key, value: value, expiry: expiry)
    }

    /**
     * Adds all key-value pairs from the `DataObject` to the pending transaction.
     *
     * The `DataLayer` will not be changed until the transaction is committed. Putting after commit does nothing.
     *
     * - Parameters:
     *      - dataObject: A `DataObject` containing the key-value pairs to be stored.
     *      - expiry: The time frame for this data to remain stored.
     */
    public func putAll(dataObject: DataObject, expiry: Expiry) {
        _ = editor.putAll(dataObject: dataObject, expiry: expiry)
    }

    /**
     * Adds the removal of an individual key to the pending transaction.
     *
     * The `DataLayer` will not be changed until the transaction is committed. Removing after commit does nothing.
     *
     * - Parameter key: The key to remove from the `DataLayer`.
     */
    public func remove(key: String) {
        _ = editor.remove(key: key)
    }

    /**
     * Adds the removal of multiple keys to the pending transaction.
     *
     * The `DataLayer` will not be changed until the transaction is committed. Removing after commit does nothing.
     *
     * - Parameter keys: The list of keys to remove from the `DataLayer`.
     */
    public func remove(keys: [String]) {
        _ = editor.remove(keys: keys)
    }

    /**
     * Adds the removal of all the entries of the `DataLayer` to the pending transaction, before then adding any other key-value pair.
     *
     * The `DataLayer` will not be changed until the transaction is committed. Clearing after commit does nothing.
     */
    public func clear() {
        _ = editor.clear()
    }

    /**
     * Reads the current, already committed, value for a key from the `DataLayer`.
     *
     * Applied, but not committed, edits won't be reflected in the value returned by this method.
     *
     * This is the only read requirement of `DataItemExtractor`: all its other typed getters, such as `get(key:as:)`, are derived from it.
     *
     * - Parameter key: The key used to look up data in the `DataLayer`.
     * - Returns: The `DataItem` if one was found for the provided key.
     */
    public func getDataItem(key: String) -> DataItem? {
        dataStore.getDataItem(key: key)
    }

    /**
     * Reads a dictionary containing all the current, already committed, data in the `DataLayer`.
     *
     * Applied, but not committed, edits won't be reflected in the value returned by this method.
     *
     * - Returns: A `DataObject` dictionary with all the data currently stored in the `DataLayer`.
     */
    public func getAll() -> DataObject {
        dataStore.getAll()
    }

    /**
     * Reads all the keys currently, already committed, stored in the `DataLayer`.
     *
     * Applied, but not committed, edits won't be reflected in the value returned by this method.
     *
     * - Returns: A list of all string keys present in the `DataLayer`.
     */
    public func keys() -> [String] {
        dataStore.keys()
    }

    /**
     * Reads the number of entries currently, already committed, stored in the `DataLayer`.
     *
     * Applied, but not committed, edits won't be reflected in the value returned by this method.
     *
     * - Returns: The count of all key-value pairs in the `DataLayer`.
     */
    public func count() -> Int {
        dataStore.count()
    }

    /**
     * Commits the pending edits. It will commit all the edits that were previously applied.
     *
     * Committing more than once does nothing, even if the first commit had nothing to write or failed.
     *
     * - Throws: An error when the transaction fails.
     */
    public func commit() throws {
        try editor.commit()
    }
}
