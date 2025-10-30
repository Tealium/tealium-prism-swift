//
//  JSONPath+Parse.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension JSONPath {
    /**
     * Parses a string into an array of `JSONPathComponent`s.
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
     * - `[123].property`
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
     * - `container[""property""]`: unescaped quote (`"`)
     * - `array[12 3]`: invalid number with whitespace ( ) inside index brackets
     * - `container@property`: invalid character (`@`)
     *
     * - parameter pathString: The `String` that will be parsed.
     * - returns: An array of `JSONPathComponent`, if the parsing succeeded.
     * - throws: A `JSONPathParseError` if the parsing failed.
     */
    static func parseComponents(_ pathString: String) throws(JSONPathParseError) -> [JSONPathComponent<Root>] {
        do {
            return try JSONPathParser<Root>(pathString: pathString).start()
        } catch {
            throw JSONPathParseError(kind: error, pathString: pathString)
        }
    }
}
