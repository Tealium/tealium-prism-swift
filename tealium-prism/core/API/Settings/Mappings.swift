//
//  Mappings.swift
//  tealium-prism
//
//  Created by Tealium on 22/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * The `Mappings` builder is used to build up key/destination mappings used when optionally
 * translating the full `Dispatch` payload to just the relevant data for any given `Dispatcher`.
 *
 * Use the `from` method to supply the required source "key" and "destination" key, as
 * well as any optional "path" entries required to access keys in nested object.
 *
 * Using the following payload `DataObject` as an example (shown as JSON)
 * ```json
 * {
 *      "source" : "value",
 *      "path": {
 *          "to" : [{
 *              "source": "nested value",
 *          }]
 *      }
 * }
 * ```
 *
 * Simple usage for keys in the top level `DataObject` would look like so:
 * ```swift
 * .from("source", to: "destination")
 * ```
 *
 * More complex versions requiring accessing keys that exist in nested objects and arrays would look like so:
 * ```swift
 * .from(JSONPath["path"]["to"][0]["source"],
 *       to: JSONPath["path"]["to"]["destination"])
 * ```
 *
 * Use the `keep` utility method to create a `Mappings` that map the source `key` to the same `destination`.
 *
 * Simple usage for keys in the top level `DataObject` would look like so:
 * ```swift
 * .keep("source")
 * ```
 *
 * More complex versions requiring accessing keys that exist in nested objects would look like so:
 * ```swift
 * .keep(JSONPath["path"]["to"][0]["source"])
 * ```
 *
 * The `from` and `keep` methods return a `VariableOptions` that allows for setting optional properties relevant to a mapping
 * like a `ifValueEquals(:)`, to only perform the mapping if the value is equal to some specific string.
 *
 *
 * Use the `constant` method to supply a constant "value" and "destination" key.
 *
 * ```swift
 * .constant("value", to: "destination")
 * ```
 *
 * More complex versions requiring accessing keys that exist in nested objects would look like so:
 * ```swift
 * .constant(value, to: JSONPath["path"]["to"]["destination"])
 * ```
 *
 * The `constant` method returns a `ConstantOptions` that allows for setting optional properties relevant to a mapping
 * like a `ifValueIn(:equals:)`, to only perform the mapping if a value at the given `key` is equal to the given `target`.
 */
public class Mappings {
    fileprivate var reference: ReferenceContainer?
    fileprivate let destination: ReferenceContainer
    fileprivate var filter: ValueContainer?
    fileprivate let mapTo: ValueContainer?

    fileprivate init(reference: ReferenceContainer, destination: ReferenceContainer) {
        self.reference = reference
        self.destination = destination
        self.mapTo = nil
    }

    fileprivate init(constant: String, destination: ReferenceContainer) {
        self.mapTo = ValueContainer(constant)
        self.destination = destination
    }

    /// Builds and returns a `MappingOperation` instance.
    /// - Returns: The constructed transformation operation.
    func build() -> MappingOperation {
        let parameters = MappingParameters(reference: reference, filter: filter, mapTo: mapTo)
        return MappingOperation(destination: destination, parameters: parameters)
    }

    /// Some `Mappings` options that are mapping a key from the payload to a destination in the result payload.
    public class VariableOptions: Mappings {
        /**
         *  Sets a filter condition that the variable must match to be mapped.
         *
         *  - Parameter target: The target value that the variable needs to equal.
         *  - Returns: The `Mappings` builder.
         */
        public func ifValueEquals(_ target: String) -> Mappings {
            self.filter = ValueContainer(target)
            return self
        }
    }

    /// Some `Mappings` options that are mapping a constant value to a destination in the result payload.
    public class ConstantOptions: Mappings {
        /**
         * Sets an optional basic condition that the value at the given mapping `path` needs to match
         * in order for this mapping to take place, where the variable may be found in a `path` at the root
         * or in any nested JSON object and JSON array of the data layer.
         *
         * - Parameters:
         *      - path: The `path` to take the value from when comparing against the expected `value`.
         *      - target: The target value that the source key should contain.
         * - Returns: The `Mappings` builder.
         */
        public func ifValueIn(_ path: JSONObjectPath, equals target: String) -> Mappings {
            self.reference = ReferenceContainer(path: path)
            self.filter = ValueContainer(target)
            return self
        }

        /**
         * Sets an optional basic condition that the value at the given mapping `key` needs to match
         * in order for this mapping to take place, where the variable may be found in a `key` at the root of the data layer.
         *
         * - Parameters:
         *      - key: The `key` to take the value from when comparing against the expected `value`.
         *      - target: The target value that the source key should contain.
         * - Returns: The `Mappings` builder.
         */
        public func ifValueIn(_ key: String, equals target: String) -> Mappings {
            self.reference = ReferenceContainer(key: key)
            self.filter = ValueContainer(target)
            return self
        }
    }
}

public extension Mappings {
    /**
     * Creates a new mapping operation builder with the specified source and destination.
     *
     * - Parameters:
     *   - key: The source key from which to take the value to map.
     *   - destination: The destination path to a variable in the data layer.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    static func from(_ key: String, to destination: JSONObjectPath) -> VariableOptions {
        VariableOptions(reference: ReferenceContainer(key: key), destination: ReferenceContainer(path: destination))
    }

    /**
     * Creates a new mapping operation builder with the specified source and destination.
     *
     * - Parameters:
     *   - path: The source path from which to take the value to map.
     *   - destination: The destination path to a variable in the data layer.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    static func from(_ path: JSONObjectPath, to destination: JSONObjectPath) -> VariableOptions {
        VariableOptions(reference: ReferenceContainer(path: path), destination: ReferenceContainer(path: destination))
    }

    /**
     * Creates a new mapping operation builder with the specified source and destination.
     *
     * - Parameters:
     *   - path: The source path from which to take the value to map.
     *   - destination: The destination key to a variable in the data layer.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    static func from(_ path: JSONObjectPath, to destination: String) -> VariableOptions {
        VariableOptions(reference: ReferenceContainer(path: path), destination: ReferenceContainer(key: destination))
    }

    /**
     * Creates a new mapping operation builder with the specified source and destination.
     *
     * - Parameters:
     *   - key: The source key from which to take the value to map.
     *   - destination: The destination key to a variable in the data layer.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    static func from(_ key: String, to destination: String) -> VariableOptions {
        VariableOptions(reference: ReferenceContainer(key: key), destination: ReferenceContainer(key: destination))
    }

    /**
     * Adds a mapping where the `key` is both the source and destination of the mapping.
     *
     * - Parameter key: The key to take the value from and also the destination to place it in the mapped payload.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    static func keep(_ key: String) -> VariableOptions {
        from(key, to: key)
    }

    /**
     * Adds a mapping where the `path` is both the source and destination of the mapping.
     *
     * - Parameter path: The path to take the value from and also the destination to place it in the mapped payload.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    static func keep(_ path: JSONObjectPath) -> VariableOptions {
        from(path, to: path)
    }

    /**
     * Adds a mapping where the value to map is given by the constant `value` and will be mapped to
     * the given `destination` located/stored at some configured level of nesting as defined by
     * the `JSONObjectPath`.
     *
     *
     * - Parameters:
     *      - parameter value: The constant value to map to the given destination.
     *      - parameter destination: The destination path to store the mapped value.
     * - Returns: A `ConstantOptions` mapping operation builder.
     */
    static func constant(_ value: String, to destination: JSONObjectPath) -> ConstantOptions {
        ConstantOptions(constant: value, destination: ReferenceContainer(path: destination))
    }

    /**
     * Adds a mapping where the value to map is given by the constant `value` and will be mapped to
     * the given `destination` located/stored in the root of the data layer..
     *
     *
     * - Parameters:
     *      - parameter value: The constant value to map to the given destination.
     *      - parameter destination: The destination key to store the mapped value.
     * - Returns: A `ConstantOptions` mapping operation builder.
     */
    static func constant(_ value: String, to destination: String) -> ConstantOptions {
        ConstantOptions(constant: value, destination: ReferenceContainer(key: destination))
    }
}
