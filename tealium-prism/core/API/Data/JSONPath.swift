//
//  JSONPath.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// An internal protocol used to differentiate between `ObjectRoot` and `ArrayRoot`.
/// Do not adopt this protocol in other types.
public protocol PathRoot { }
/// A Phantom Type used to specify a type of `JSONPath` that can be applied to a JSON object.
public enum ObjectRoot: PathRoot { }
/// A Phantom Type used to specify a type of `JSONPath` that can be applied to a JSON array.
public enum ArrayRoot: PathRoot { }

/**
 * A `JSONPath` that can be applied to a JSON object to represent the path to a potentially nested value.
 * Nested items can be in both JSON objects and JSON arrays.
 *
 * To create a path like `container.array[0].property` you can use a subscript for each path component:
 * ```swift
 * JSONPath["container"]["array"][0]["property"]
 * ```
 */
public typealias JSONObjectPath = JSONPath<ObjectRoot>
/**
 * A `JSONPath` that can be applied to a JSON array to represent the path to a potentially nested value.
 * Nested items can be in both JSON objects and JSON arrays.
 *
 * To create a path like `[0].container.array[0].property` you can use a subscript for each path component:
 * ```swift
 * JSONPath[0]["container"]["array"][0]["property"]
 * ```
 */
public typealias JSONArrayPath = JSONPath<ArrayRoot>

public extension JSONPath where Root == ObjectRoot {

    var root: String {
        switch components.first {
        case let .key(key):
            return key
        default:
            fatalError("JSONObjectPath with non key as a root")
        }
    }
    /**
     * Creates a `JSONObjectPath` with the root component.
     *
     * - warning: This will not parse the given key, but rather use it in its entirety as a root key.
     * Use `JSONObjectPath.parse` to parse a complete path like `container.property`.
     *
     * - parameter key: The root component of this `JSONObjectPath`.
     */
    static subscript(_ key: String) -> Self {
        self.init(components: [.key(key)])
    }

    /**
     * Parses a string into a `JSONObjectPath`.
     *
     * The string to pass needs to conform to a specific format.
     * - It can be a dot (`.`) separated list of alphanumeric characters and/or underscores.
     *      - Each component of a list built this way represents one level of a JSON object.
     *      - The last one can represent any type of JSON value.
     * - Square brackets (`[]`)  could be used instead of the dot notation, to separate one (or each) of the components.
     * Inside these brackets you can put:
     *      - An integer, to represent an element into a JSON array.
     *      - A single (`'`) or double  (`"`)  quoted string to represent an element into a JSON object.
     *      - Inside of the quoted string any character is valid, but the character used to quote the string (`'` or `"`)
     *      needs to be escaped with a backslash (`\`), and same for backslashes, which need to be escaped with an additional backslash.
     * - It needs to start with a key component.
     *
     * Examples of valid strings:
     * - `property`
     * - `container.property`
     * - `container["property"]`
     * - `container['property']`
     * - `container["john's party"]`
     * - `container['john\'s party']`
     * - `container["\"nested quote\""]`
     * - `container["escaped\\backslash"]`
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
     * - `container["property']`: closing quote (`'`) different from opening one (`"`) in brackets
     * - `container['john's party']`: unescaped quote (`'`)
     * - `container[""nested quote""]`: unescaped quotes (`"`)
     * - `container["unescaped\backslash"]`: unescaped backslash (`\`)
     * - `array[12 3]`: invalid number with whitespace ( ) inside index brackets
     * - `container@property`: invalid character (`@`)
     * - `[123].property`: index is not valid as a first component. Must start with a key.
     *
     * - parameter pathString: The `String` that will be parsed.
     * - returns: A `JSONObjectPath`, if the parsing succeeded.
     * - throws: A `JSONPathParseError` if the parsing failed.
     */
    static func parse(_ pathString: String) throws(JSONPathParseError) -> JSONPath<Root> {
        let components = try JSONPath<Root>.parseComponents(pathString)
        guard case .key = components.first else {
            throw JSONPathParseError(kind: .invalidFirstComponent, pathString: pathString)
        }
        return self.init(components: components)
    }
}

public extension JSONPath where Root == ArrayRoot {
    /**
     * Creates a `JSONArrayPath` with the root component.
     *
     * - parameter index: The root component of this `JSONArrayPath`.
     */
    static subscript(_ index: Int) -> Self {
        self.init(components: [.index(index)])
    }

    /**
     * Parses a string into a `JSONArrayPath`.
     *
     * The string to pass needs to conform to a specific format.
     * - It can be a dot (`.`) separated list of alphanumeric characters and/or underscores.
     *      - Each component of a list built this way represents one level of a JSON object.
     *      - The last one can represent any type of JSON value.
     * - Square brackets (`[]`)  could be used instead of the dot notation, to separate one (or each) of the components.
     * Inside these brackets you can put:
     *      - An integer, to represent an element into a JSON array.
     *      - A single (`'`) or double  (`"`)  quoted string to represent an element into a JSON object.
     *      - Inside of the quoted string any character is valid, but the character used to quote the string (`'` or `"`)
     *      needs to be escaped with a backslash (`\`), and same for backslashes, which need to be escaped with an additional backslash.
     * - It needs to start with an index component.
     *
     * Examples of valid strings:
     * - `[123]`
     * - `[0].property`
     * - `[0]["property"]`
     * - `[0]['property']`
     * - `[0]["john's party"]`
     * - `[0]['john\'s party']`
     * - `[0]["\"nested quote\""]`
     * - `[0]["escaped\\backslash"]`
     * - `[0][123]`
     *      - which is different from `[0]["123"]`, although both are valid.
     *      Difference is that the quoted version treats the `[0]` item as an object and looks for a nested "123" by string instead of the item at index 123 in an array.
     * - `[0].array[123].property`
     * - `[0].some_property`
     * - `[0].container.some_property`
     * - `[0].container["some.property"]`
     *      - which is different from `[0].container.some.property`, although both are valid
     * - `[0].container["some@property"]`
     *      - which would be wrong without the quoted brackets: `container.some@property`)
     * - `[0]["array"][123]["property"]`
     *
     * Examples of invalid strings:
     * - `[0]."property"`: invalid character (`"`)
     * - `[0].container-property`: invalid character (`-`)
     * - `[0].container[property]`: missing quotes (`"`) in brackets
     * - `[0].container.["property"]`: invalid character (`.`) before the brackets
     * - `[0].container["property']`: closing quote (`'`) different from opening quote (`"`) in brackets
     * - `[0]['john's party']`: unescaped quote (`'`)
     * - `[0][""nested quote""]`: unescaped quotes (`"`)
     * - `[0]["unescaped\backslash"]`: unescaped backslash (`\`)
     * - `[12 3]`: invalid number with whitespace ( ) inside index brackets
     * - `[0].container@property`: invalid character (`@`)
     * - `property`: key is not a valid first component. Must start with an index.
     *
     * - parameter pathString: The `String` that will be parsed.
     * - returns: A `JSONArrayPath`, if the parsing succeeded.
     * - throws: A `JSONPathParseError` if the parsing failed.
     */
    static func parse(_ pathString: String) throws(JSONPathParseError) -> JSONPath<Root> {
        let components = try JSONPath<Root>.parseComponents(pathString)
        guard case .index = components.first else {
            throw JSONPathParseError(kind: .invalidFirstComponent, pathString: pathString)
        }
        return self.init(components: components)
    }
}

/**
 * A structure representing the location of an item in a JSON object or JSON array, potentially nested in other JSON objects and JSON arrays.
 *
 *
 * To create a basic `JSONPath` you can call the `JSONPath` subscript with a `String` or an `Int` depending on where you want to start the path from: the first one would start from a JSON object, the second would start from a JSON array.
 * ```swift
 * let objectPath = JSONPath["container"]
 * let arrayPath = JSONPath[0]
 * ```
 *
 * To create a path like `container.array[0].property` you can use a subscript for each path component:
 * ```swift
 * JSONPath["container"]["array"][0]["property"]
 * ```
 */
public struct JSONPath<Root: PathRoot> {
    let components: [JSONPathComponent<Root>]

    /// Create a JSONPath with a non empty array of `JSONPathComponent`s.
    /// The first item needs to be a key if `Root` is an `ObjectRoot` or an index if `Root` is an `ArrayRoot`.
    fileprivate init(components: [JSONPathComponent<Root>]) {
        self.components = components
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
     * `JSONPath["root"]["property"]` will point to the value `"item"`.
     *
     * - parameter key: The key to look for an item in an object, after reaching the current path component.
     * - returns: A new `JSONPath`, that has the key lookup appended at the end of the current path.
     */
    public subscript(_ key: String) -> Self {
        JSONPath<Root>(components: components + [.key(key)])
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
     * `JSONPath["root"][0]` will point to the value `"item"`.
     *
     * - parameter index: The index to look for an item in an array, after reaching the current path component.
     * - returns: A new `JSONPath`, that has the index lookup appended at the end of the current path.
     */
    public subscript(_ index: Int) -> Self {
        JSONPath<Root>(components: components + [.index(index)])
    }
}
