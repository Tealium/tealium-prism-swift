//
//  Mappings.swift
//  tealium-swift
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
 *          "to" : {
 *              "source": "nested value"
 *          }
 *      }
 * }
 * ```
 *
 * Simple usage for keys in the top level `DataObject` would look like so:
 * ```swift
 * .from("source", to: "destination")
 * ```
 *
 * More complex versions requiring accessing keys that exist in nested objects would look like so:
 * ```swift
 * .from(VariableAccessor(path: ["path", "to"], variable: "source"),
 *       to: VariableAccessor(path: ["path", "to"], variable: "destination"))
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
 * .keep(VariableAccessor(path: ["path", "to"], variable: "source"))
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
 * .constant(value, to: VariableAccessor(path: ["path", "to"], variable: "destination"))
 * ```
 *
 * The `constant` method returns a `ConstantOptions` that allows for setting optional properties relevant to a mapping
 * like a `ifValueIn(:equals:)`, to only perform the mapping if a value at the given `key` is equal to the given `target`.
 *
 * Refer to the `VariableAccessor` documentation for suggested ways to store constant accessors that you can reuse in your code.
 */
public class Mappings {
    fileprivate(set) var key: VariableAccessor?
    fileprivate let destination: VariableAccessor
    fileprivate(set) var filter: ValueContainer?
    fileprivate let mapTo: ValueContainer?

    fileprivate init(key: VariableAccessor, destination: VariableAccessor) {
        self.key = key
        self.destination = destination
        self.mapTo = nil
    }

    fileprivate init(constant: String, destination: VariableAccessor) {
        self.mapTo = ValueContainer(constant)
        self.destination = destination
    }

    /// Builds and returns a `MappingOperation` instance.
    /// - Returns: The constructed transformation operation.
    func build() -> MappingOperation {
        let parameters = MappingParameters(key: key, filter: filter, mapTo: mapTo)
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
         * Sets an optional basic condition that the value at the given mapping `key` needs to match
         * in order for this mapping to take place, where the `key` may be found in a configured level
         * of nesting according to the `VariableAccessor.path`
         *
         * - Parameters:
         *      - key: The `key` to take the value from when comparing against the expected `value`.
         *      - target: The target value that the source key should contain.
         * - Returns: The `Mappings` builder.
         */
        public func ifValueIn(_ key: VariableAccessor, equals target: String) -> Mappings {
            self.key = key
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
     *   - key: The source `VariableAccessor` from which to take the value to map.
     *   - destination: The destination variable accessor.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    static func from(_ key: VariableAccessor, to destination: VariableAccessor) -> VariableOptions {
        VariableOptions(key: key, destination: destination)
    }

    /**
     * Adds a mapping where the `key` is both the source and destination of the mapping.
     *
     * - Parameter key: The `VariableAccessor` to take the value from and also the destination to place it in the mapped payload.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    static func keep(_ key: VariableAccessor) -> VariableOptions {
        from(key, to: key)
    }

    /**
     * Adds a mapping where the value to map is given by the constant `value` and will be mapped to
     * the given `destination` located/stored at some configured level of nesting as defined by
     * the `VariableAccessor.path`.
     *
     *
     * - Parameters:
     *      - parameter value: The constant value to map to the given [destination]
     *      - parameter destination: The [destination] key to store the mapped value
     * - Returns: A `ConstantOptions` mapping operation builder.
     */
    static func constant(_ value: String, to destination: VariableAccessor) -> ConstantOptions {
        ConstantOptions(constant: value, destination: destination)
    }
}
