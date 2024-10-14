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
     * In case of duplicate keys the second occurrance of the same key will replace the first one.
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
     * In case of duplicate keys the second occurrance of the same key will replace the first one.
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
        self.dictionary = dictionary.compactMapValues { $0.toDataInput() }
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
