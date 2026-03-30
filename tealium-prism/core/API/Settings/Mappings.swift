//
//  Mappings.swift
//  tealium-prism
//
//  Created by Tealium on 22/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// Base builder class for a single mapping operation. Use ``Mappings`` factory methods to create instances.
public class MappingsBuilder {
    fileprivate var reference: ReferenceContainer?
    fileprivate let destination: ReferenceContainer
    fileprivate var filter: StringContainer?
    fileprivate let mapTo: ValueContainer?

    fileprivate init(reference: ReferenceContainer, destination: ReferenceContainer) {
        self.reference = reference
        self.destination = destination
        self.mapTo = nil
    }

    fileprivate init(constant: DataInput, destination: ReferenceContainer) {
        self.mapTo = ValueContainer(constant)
        self.destination = destination
    }

    func build() -> MappingOperation {
        let parameters = MappingParameters(reference: reference, filter: filter, mapTo: mapTo)
        return MappingOperation(destination: destination, parameters: parameters)
    }
}

/**
 * The `Mappings` builder is used to build up key/destination mappings used when optionally
 * translating the full `Dispatch` payload to just the relevant data for any given `Dispatcher`.
 *
 * Use the `mapFrom` method to supply the required source "key" and "destination" key, as
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
 * mappings.mapFrom("source", to: "destination")
 * ```
 *
 * More complex versions requiring accessing keys that exist in nested objects and arrays would look like so:
 * ```swift
 * mappings.mapFrom(JSONPath["path"]["to"][0]["source"],
 *                  to: JSONPath["path"]["to"]["destination"])
 * ```
 *
 * Use the `keep` utility method to create a mapping where the source `key` is the same as the `destination`.
 *
 * Simple usage for keys in the top level `DataObject` would look like so:
 * ```swift
 * mappings.keep("source")
 * ```
 *
 * More complex versions requiring accessing keys that exist in nested objects would look like so:
 * ```swift
 * mappings.keep(JSONPath["path"]["to"][0]["source"])
 * ```
 *
 * The `mapFrom` and `keep` methods return a `VariableOptions` that allows for setting optional properties relevant to a mapping
 * like a `ifValueEquals(:)`, to only perform the mapping if the value is equal to some specific string.
 *
 *
 * Use the `mapConstant` method to supply a constant "value" and "destination" key.
 *
 * ```swift
 * mappings.mapConstant("value", to: "destination")
 * ```
 *
 * More complex versions requiring accessing keys that exist in nested objects would look like so:
 * ```swift
 * mappings.mapConstant(value, to: JSONPath["path"]["to"]["destination"])
 * ```
 *
 * The `mapConstant` method returns a `ConstantOptions` that allows for setting optional properties relevant to a mapping
 * like a `ifValueIn(:equals:)`, to only perform the mapping if a value at the given `key` is equal to the given `target`.
 */
open class Mappings {
    var mappingsList: [MappingsBuilder] = []

    /// Creates an empty `Mappings` instance. Add operations with `mapFrom`, `keep`, or `mapConstant`.
    required public init() { }

    /// Builds and returns an array of `MappingOperation` instances.
    /// - Returns: The constructed transformation operations.
    func build() -> [MappingOperation] {
        mappingsList.map { $0.build() }
    }

    /// Some `Mappings` options that are mapping a key from the payload to a destination in the result payload.
    public class VariableOptions: MappingsBuilder {
        override init(reference: ReferenceContainer, destination: ReferenceContainer) {
            super.init(reference: reference, destination: destination)
        }
        /**
         *  Sets a filter condition that the variable must match to be mapped.
         *
         *  - Parameter target: The target value that the variable needs to equal.
         */
        public func ifValueEquals(_ target: String) {
            self.filter = StringContainer(target)
        }
    }

    /// Some `Mappings` options that are mapping a constant value to a destination in the result payload.
    public class ConstantOptions: MappingsBuilder {
        override init(constant: DataInput, destination: ReferenceContainer) {
            super.init(constant: constant, destination: destination)
        }
        /**
         * Sets an optional basic condition that the value at the given mapping `path` needs to match
         * in order for this mapping to take place, where the variable may be found in a `path` at the root
         * or in any nested JSON object and JSON array of the data layer.
         *
         * - Parameters:
         *      - path: The `path` to take the value from when comparing against the expected `value`.
         *      - target: The target value that the source key should contain.
         */
        public func ifValueIn(_ path: JSONObjectPath, equals target: String) {
            self.reference = .path(path)
            self.filter = StringContainer(target)
        }

        /**
         * Sets an optional basic condition that the value at the given mapping `key` needs to match
         * in order for this mapping to take place, where the variable may be found in a `key` at the root of the data layer.
         *
         * - Parameters:
         *      - key: The `key` to take the value from when comparing against the expected `value`.
         *      - target: The target value that the source key should contain.
         */
        public func ifValueIn(_ key: String, equals target: String) {
            self.reference = .key(key)
            self.filter = StringContainer(target)
        }
    }

    /// A `ConstantOptions` instance that is mapping a command name string to the "command_name" property in the result payload.
    /// Intended to be used for so called Remote Command Dispatchers.
    public class CommandOptions: ConstantOptions {
        init(commandName: String) {
            super.init(constant: commandName, destination: .key(TealiumDataKey.commandName))
        }

        /**
         * Configures this command mapping to only apply to event-type dispatches.
         * This adds a filter condition that checks if the event type equals "event".
         */
        public func forAllEvents() {
            self.reference = .key(TealiumDataKey.eventType)
            self.filter = StringContainer(DispatchType.event.rawValue)
        }

        /**
         * Configures this command mapping to only apply to view-type dispatches.
         * This adds a filter condition that checks if the event type equals "view".
         */
        public func forAllViews() {
            self.reference = .key(TealiumDataKey.eventType)
            self.filter = StringContainer(DispatchType.view.rawValue)
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
    @discardableResult
    func mapFrom(_ key: String, to destination: JSONObjectPath) -> VariableOptions {
        mapFrom(.key(key), to: .path(destination))
    }

    /**
     * Creates a new mapping operation builder with the specified source and destination.
     *
     * - Parameters:
     *   - path: The source path from which to take the value to map.
     *   - destination: The destination path to a variable in the data layer.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    @discardableResult
    func mapFrom(_ path: JSONObjectPath, to destination: JSONObjectPath) -> VariableOptions {
        mapFrom(.path(path), to: .path(destination))
    }

    /**
     * Creates a new mapping operation builder with the specified source and destination.
     *
     * - Parameters:
     *   - path: The source path from which to take the value to map.
     *   - destination: The destination key to a variable in the data layer.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    @discardableResult
    func mapFrom(_ path: JSONObjectPath, to destination: String) -> VariableOptions {
        mapFrom(.path(path), to: .key(destination))
    }

    /**
     * Creates a new mapping operation builder with the specified source and destination.
     *
     * - Parameters:
     *   - key: The source key from which to take the value to map.
     *   - destination: The destination key to a variable in the data layer.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    @discardableResult
    func mapFrom(_ key: String, to destination: String) -> VariableOptions {
        mapFrom(.key(key), to: .key(destination))
    }

    /**
     * Adds a mapping where the `key` is both the source and destination of the mapping.
     *
     * - Parameter key: The key to take the value from and also the destination to place it in the mapped payload.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    @discardableResult
    func keep(_ key: String) -> VariableOptions {
        keep(.key(key))
    }

    /**
     * Adds a mapping where the `path` is both the source and destination of the mapping.
     *
     * - Parameter path: The path to take the value from and also the destination to place it in the mapped payload.
     * - Returns: A `VariableOptions` mapping operation builder.
     */
    @discardableResult
    func keep(_ path: JSONObjectPath) -> VariableOptions {
        keep(.path(path))
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
    @discardableResult
    func mapConstant(_ value: DataInput, to destination: JSONObjectPath) -> ConstantOptions {
        mapConstant(value, to: .path(destination))
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
    @discardableResult
    func mapConstant(_ value: DataInput, to destination: String) -> ConstantOptions {
        mapConstant(value, to: .key(destination))
    }

    /**
     * Adds a mapping where the value to map is given by the constant `name` and will be mapped to
     * the "command_name" key located in the root of the data layer.
     *
     * - Parameter name: The command name to map to the "command_name" property key.
     * - Returns: A `CommandOptions` mapping operation builder.
     */
    @discardableResult
    func mapCommand(_ name: String) -> CommandOptions {
        let builder = CommandOptions(commandName: name)
        mappingsList.append(builder)
        return builder
    }

    private func mapFrom(_ source: ReferenceContainer, to destination: ReferenceContainer) -> VariableOptions {
        let builder = VariableOptions(reference: source, destination: destination)
        mappingsList.append(builder)
        return builder
    }

    private func mapConstant(_ value: DataInput, to destination: ReferenceContainer) -> ConstantOptions {
        let builder = ConstantOptions(constant: value, destination: destination)
        mappingsList.append(builder)
        return builder
    }

    private func keep(_ reference: ReferenceContainer) -> VariableOptions {
        mapFrom(reference, to: reference)
    }
}
