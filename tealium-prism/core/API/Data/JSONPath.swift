//
//  JSONPath.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A structure representing the location of an item in a JSON object, potentially nested in other JSON objects and in JSON arrays.
 */
public struct JSONPath: CustomStringConvertible {
    let head: JSONPathComponent

    /**
     * Creates a `JSONPath` with the root component.
     *
     * - warning: This will not parse the given key, but rather use it in its entirety as a root key.
     * Use `JSONPath.parse` to parse a complete path like `container.property`.
     *
     * - parameter key: The root component of this `JSONPath`.
     */
    public init(_ key: String) {
        self.init(head: .key(key, next: nil))
    }

    private init(head: JSONPathComponent) {
        self.head = head
    }

    /**
     * Creates a new `JSONPath` starting from self and adding a new component that looks up for an item in an array at the given index.
     *
     * As an example, given the following JSON:
     * ```json
     * {
     *   "root": [
     *      "item"
     *   ]
     * }
     * ```
     * `JSONPath("root")[0]` will point to the value `"item"`.
     *
     * - parameter index: The index to look for an item in an array, after reaching the current path.
     * - returns: A new `JSONPath`, that has the index lookup appended at the end of the current path.
     */
    public subscript(_ index: Int) -> JSONPath {
        self + .index(index, next: nil)
    }

    /**
     * Creates a new `JSONPath` starting from self and adding a new component that looks up for an item in an object at the given key.
     *
     * As an example, given the following JSON:
     * ```json
     * {
     *   "root": {
     *      "property": "item"
     *   }
     * }
     * ```
     * `JSONPath("root")["property"]` will point to the value `"item"`.
     *
     * - parameter key: The key to look for an item in an object, after reaching the current path.
     * - returns: A new `JSONPath`, that has the key lookup appended at the end of the current path.
     */
    public subscript(_ key: String) -> JSONPath {
        self + .key(key, next: nil)
    }

    public var description: String {
        head.description
    }

    static func + (path: JSONPath, component: JSONPathComponent) -> JSONPath {
        JSONPath(head: path.head + component)
    }

    static func += (path: inout JSONPath, component: JSONPathComponent) {
        path = JSONPath(head: path.head + component)
    }

    /**
     * Parses a string into a `JSONPath`.
     *
     * The string to pass needs to conform to a specific format.
     * - It can be a dot (`.`) separated list of alphanumeric characters and/or underscores.
     *      - Each component of a list built this way represents one level of a JSON object.
     *      - The last one can represent any type of JSON value.
     * - Square brackets (`[]`)  could be used instead of the dot notation, to separate one (or each) of the components.
     * Inside of these brackets you can put:
     *      - An integer, to represent an element into a JSON array.
     *      - A quoted string (`""`) to represent an element into a JSON object.
     *      Inside of the quoted string any character is valid, except for other quotes (`"`).
     *
     * Examples of valid strings:
     * - `property`
     * - `container.property`
     * - `container["property"]`
     * - `array[123]`
     *      - which is different from `array["123"]`, although both are valid.
     *      Difference is that the quoted version treats the `array` property as an object and looks for a nested "123" by string instead of the item at index 123 in an array.
     * - `array[123].property`
     * - `some_property`
     * - `container.some_property`
     * - `container["some.property"]`
     *      - which is different from `container.some.property`, although both are valid
     * - `container["some@property"]`
     *      - which would be wrong without the quoted brackets: `container.some@property`)
     * - `["array"][123]["property"]`
     *
     * Examples of invalid strings:
     * - `"property"`: invalid character (`"`)
     * - `container-property`: invalid character (`-`)
     * - `container[property]`: missing quotes (`"`) in brackets
     * - `container.["property"]`: invalid character (`.`) before the brackets
     * - `array[12 3]`: invalid number with whitespace ( ) inside index brackets
     * - `container@property`: invalid character (`@`)
     *
     * - parameter pathString: The `String` that will be parsed.
     * - returns: A `JSONPath`, if the parsing succeeded.
     * - throws: A `JSONPathParseError` if the parsing failed.
     */
    public static func parse(_ pathString: String) throws(JSONPathParseError) -> JSONPath {
        do {
            return try JSONPathParsing(pathString: pathString).start()
        } catch {
            throw JSONPathParseError(kind: error, pathString: pathString)
        }
    }
}

extension JSONPath: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    /**
     * Creates a `JSONPath` with the root component.
     *
     * - warning: This will not parse the given key, but rather use it in its entirety as a root key.
     * Use `JSONPath.parse` to parse a complete path like `container.property`.
     *
     * - parameter key: The root component of this `JSONPath`.
     */
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension JSONPath: Equatable {
    public static func == (lhs: JSONPath, rhs: JSONPath) -> Bool {
        lhs.description == rhs.description
    }
}
