//
//  DataObject.swift
//  tealium-swift
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
        }, uniquingKeysWith: { _, second in
            second
        })
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
     * Extracts a nested `DataItem` according to the given `accessor`.
     *
     * If the `VariableAccessor.variable` is not found at the `VariableAccessor.path`, or any path
     * component is not also a `DataObject`, `nil` will be returned.
     *
     * - Parameters:
     *      - accessor: The `VariableAccessor` describing how to access the variable.
     * - Returns: The required `DataItem` if available; else `nil`.
     */
    public func extract(_ accessor: VariableAccessor) -> DataItem? {
        var extractor: DataItemExtractor? = self
        if let path = accessor.path {
            for component in path where extractor != nil {
                extractor = extractor?.getDataDictionary(key: component)
            }
        }
        return extractor?.getDataItem(key: accessor.variable)
    }

    /**
     * Sets the item in the `DataObject` by following the `VariableAccessor` key and path and recursively creating the required containers.
     *
     * In case the `DataObject` contains already the nested object as expressed in the `VariableAccessor.path`
     * it will insert the new item in those object.
     * The missing containers will, instead, be automatically be created by this method.
     *
     * - Parameters:
     *      - accessor: The accessor that expresses the (eventually nested) location in which to put the item
     *      - item: The item to insert at the provided location
     */
    mutating public func buildPathAndSet(accessor: VariableAccessor, item: DataItem) {
        buildPathAndSet(key: accessor.variable, path: accessor.path, item: item)
    }

    private mutating func buildPathAndSet(key: String, path: [String]?, item: DataItem) {
        guard var path, !path.isEmpty else {
            self.set(converting: item, key: key)
            return
        }
        let firstComponent = path.removeFirst()
        var subObject = self.getDataDictionary(key: firstComponent)?.toDataObject() ?? DataObject()
        subObject.buildPathAndSet(key: key, path: path, item: item)
        self.set(converting: subObject, key: firstComponent)
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

    public func asDataObject() -> DataObject {
        return DataObject(dictionaryInput: self)
    }
}
