//
//  DataObject.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A custom wrapper around a common Dictionary used to limit the `DataInput` types into the Dictionary.
 *
 * Only valid `DataInput` types will be stored in the inner Dictionary and
 * only `DataInputConvertible` types can be used to initialize this wrapper object.
 */
public struct DataObject: ExpressibleByDictionaryLiteral {
    fileprivate var dictionary: [String: DataInput]

    /// - returns: The keys of the `DataItem` stored in this `DataObject`.
    public var keys: Dictionary<String, any DataInput>.Keys {
        dictionary.keys
    }

    /// - returns: The number of `DataItem` stored in this `DataObject`.
    public var count: Int {
        dictionary.count
    }

    /**
     * Creates a `DataObject` from a list of `(String, DataInputConvertible)` tuple.
     *
     * The first element in the tuple is the key that can be used to access the item back,
     * the second element is a convertible that will be converted immediately before being stored.
     * In case of duplicate keys the second occurrence of the same key will replace the first one.
     */
    public init(pairs elements: [(String, DataInputConvertible)]) {
        dictionary = Dictionary(elements.map { key, value in
            (key, value.toDataInput())
        }, prefersFirst: false)
    }

    /**
     * Creates a `DataObject` from a `[String: DataInputConvertible]` dictionary literal.
     *
     * The Convertible elements will be converted immediately before being stored.
     * In case of duplicate keys the second occurrence of the same key will replace the first one.
     */
    public init(dictionaryLiteral elements: (String, DataInputConvertible)...) {
        self.init(pairs: elements)
    }

    /**
     * Creates a `DataObject` from a `[String: DataInputConvertible]` dictionary.
     *
     * The Convertible elements will be converted immediately before being stored.
     */
    public init(dictionary: [String: DataInputConvertible] = [:]) {
        self.init(dictionaryInput: dictionary.mapValues { $0.toDataInput() })
    }

    /**
     * Creates a `DataObject` from a `[String: DataInputConvertible?]` dictionary.
     *
     * The Convertible elements will be converted immediately before being stored.
     * `nil`s in root object will be removed.
     */
    init(compacting dictionary: [String: DataInputConvertible?] = [:]) {
        self.init(dictionary: dictionary.compactMapValues { $0 })
    }

    /// Creates a DataObject from a dictionary of DataInput values.
    /// - Parameter dictionaryInput: The dictionary containing DataInput values.
    public init(dictionaryInput: [String: DataInput]) {
        self.dictionary = dictionaryInput
    }

    /**
     * Sets the value at the given key
     */
    mutating public func set(_ value: DataInput, key: String) {
        dictionary[key] = value
    }

    /**
     * Sets the convertible value at the given key after converting it.
     */
    mutating public func set(converting convertible: DataInputConvertible, key: String) {
        set(convertible.toDataInput(), key: key)
    }

    /// Removes the value stored at the given key.
    mutating public func removeValue(forKey key: String) {
        dictionary.removeValue(forKey: key)
    }

    /// Returns the underlying dictionary of `[String: DataInput]`.
    public func asDictionary() -> [String: DataInput] {
        dictionary
    }

    func toDataItem() -> DataItem {
        DataItem(value: asDictionary())
    }

    func getConvertible<T>(converter: any DataItemConverter<T>) -> T? {
        toDataItem().getConvertible(converter: converter)
    }

    /**
     * Sets the item in the `DataObject` by following the `JSONObjectPath` and recursively creating the required containers.
     *
     * In case the `DataObject` contains already the nested object or array as expressed in the `JSONObjectPath`
     * it will insert the new item in those objects or arrays.
     * The missing containers will, instead, be automatically be created by this method.
     * In case an array is not big enough to insert an item at the given index, nil items will be put until we reach the required capacity.
     *
     * - Parameters:
     *      - path: The `JSONObjectPath` that expresses the (eventually nested) location in which to put the item
     *      - item: The item to insert at the provided location
     */
    mutating public func buildPath(_ path: JSONObjectPath, andSet item: DataItem) {
        var components = path.components
        _ = components.removeFirst()
        self.buildPath(key: path.root, components: &components, andSet: item)
    }
}

/// Allows use of plus operator for DataObject.
public func + (lhs: DataObject, rhs: DataObject) -> DataObject {
    var lhsCopy = lhs
    lhsCopy += rhs
    return lhsCopy
}

/// Extend the use of += operators to DataObject.
public func += (left: inout DataObject, right: DataObject) {
    let rightDictionary = right.asDictionary()
    for (key, value) in rightDictionary {
        left.dictionary.updateValue(value, forKey: key)
    }
}

extension DataObject: CustomStringConvertible {
    public var description: String {
        dictionary.description
    }
}

extension DataObject {
    /**
     * Deep merges two `DataObject`s together, returning a new `DataObject` containing the merged data.
     *
     * This method will merge data according to the following rules
     *  - `DataObject`s - will have all keys from `self` and `other` in the returned `DataObject`
     *  - Arrays - will always prefer the value in the `other` object if present. Array contents are never merged.
     *
     * The `depth` parameter controls how many levels of `DataObject` nesting should be merged. After
     * the given depth, if a `DataObject` is found in both `self` and `other` objects, then the
     * latter is chosen in its entirety.
     *
     * Example
     * ```swift
     * let lhs: DataObject = [
     *     "key1": "string",
     *     "key2": true,
     *     "lvl-1": try DataItem(serializing: [
     *         "key1": "string",
     *         "key2": true,
     *         "lvl-2": [
     *             "key1": "string",
     *             "key2": true,
     *             "lvl-3": [
     *                 "key1": "string",
     *                 "key2": true,
     *             ]
     *         ]
     *     ])
     * ]
     *
     * let rhs: DataObject = [
     *     "key1": "new string",
     *     "lvl-1": try DataItem(serializing: [
     *         "key1": "new string",
     *         "lvl-2": [
     *             "key1": "new string",
     *             "lvl-3": [
     *                 "key1": "new string",
     *             ]
     *         ]
     *     ])
     * ]
     * let merged = lhs.deepMerge(with: rhs)
     *
     * // merged will be the equivalent of this:
     *
     * let result: DataObject = [
     *     "key1": "new string",            // from rhs
     *     "key2": true,                    // from lhs
     *     "lvl-1": try DataItem(serializing: [
     *         "key1": "new string",        // from rhs
     *         "key2": true,                // from lhs
     *         "lvl-2": [
     *             "key1": "new string",    // from rhs
     *             "key2": true,            // from lhs
     *             "lvl-3": [
     *                 "key1": "new string",// from rhs
     *                 "key2": true,        // from lhs
     *             ]
     *         ]
     *     ])
     * ]
     * ```
     *
     * The default value for `depth` is `Int.max`, and will deep merge all levels. Zero or
     * negative values will be equivalent to the `DataObject.plus` operator.
     *
     * - Parameters:
     *      - other: The incoming object, whose key/values are to merged into the current object.
     *      - depth: Optional limit on the number of levels deep to merge.
     */
    func deepMerge(with other: DataObject, depth: Int = Int.max) -> DataObject {
        DataObject(dictionaryInput: self.asDictionary().deepMerge(other: other.asDictionary(), depth: depth))
    }
}

extension DataObject: Equatable {
    public static func == (lhs: DataObject, rhs: DataObject) -> Bool {
        (lhs.dictionary as NSDictionary).isEqual(to: rhs.dictionary)
    }
}

extension [String: DataInput] {
    fileprivate func deepMerge(other: [String: DataInput], depth: Int) -> [String: DataInput] {
        return recursiveMerge(self, other, depth)
    }

    private func recursiveMerge(_ left: [String: DataInput], _ right: [String: DataInput], _ depth: Int) -> [String: DataInput] {
        guard depth > 0 else {
            return left + right
        }
        var result = left
        for key in right.keys {
            if let dictR = right[key] as? [String: DataInput],
                let dictL = left[key] as? [String: DataInput] {
                result[key] = recursiveMerge(dictL, dictR, depth - 1)
            } else if let value = right[key] {
                result[key] = value
            }
        }
        return result
    }

    /// Converts this dictionary to a DataObject.
    /// - Returns: A new DataObject containing the dictionary's key-value pairs.
    public func asDataObject() -> DataObject {
        return DataObject(dictionaryInput: self)
    }
}

fileprivate extension DataObject {
     mutating func buildPath<Root: PathRoot>(key: String, components: inout [JSONPathComponent<Root>], andSet item: DataItem) {
        guard !components.isEmpty else {
            set(converting: item, key: key)
            return
        }
        let component = components.removeFirst()
        let nested = self.getDataItem(key: key)
        switch component {
        case let .index(index):
            var array = nested?.getDataArray() ?? []
            array.buildPath(index: index, components: &components, andSet: item)
            set(converting: array, key: key)
        case let .key(internalKey):
            let dictionary = nested?.getDataDictionary() ?? [:]
            var dataObject = dictionary.toDataObject()
            dataObject.buildPath(key: internalKey, components: &components, andSet: item)
            set(converting: dataObject, key: key)
        }
    }
}

fileprivate extension Array where Element == DataItem {
    mutating func buildPath<Root: PathRoot>(index: Int, components: inout [JSONPathComponent<Root>], andSet item: DataItem) {
        guard !components.isEmpty else {
            self[safe: index] = item
            return
        }
        let component = components.removeFirst()
        let nested = self[safe: index]
        switch component {
        case let .index(internalIndex):
            var array = nested?.getDataArray() ?? []
            array.buildPath(index: internalIndex, components: &components, andSet: item)
            self[safe: index] = DataItem(converting: array)
        case let .key(key):
            let dictionary = nested?.getDataDictionary() ?? [:]
            var dataObject = dictionary.toDataObject()
            dataObject.buildPath(key: key, components: &components, andSet: item)
            self[safe: index] = DataItem(converting: dataObject)
        }
    }
}
