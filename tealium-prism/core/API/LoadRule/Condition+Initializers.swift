//
//  Condition+Initializers.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

public extension Condition {
    /**
     * Returns a `Condition` that checks whether the value found at path `variable` is equal to
     * the given `target`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the equality check should be done in a case-insensitive way; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - target: the target value to check against
     */
    static func equals(ignoreCase: Bool, variable: JSONObjectPath, target: String) -> Self {
        Condition(variable: variable, operator: .equals(ignoreCase), filter: ValueContainer(target))
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable` is equal to
     * the given `target`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the equality check should be done in a case-insensitive way; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - target: the target value to check against
     */
    static func equals(ignoreCase: Bool, variable: String, target: String) -> Self {
        Condition(variable: variable, operator: .equals(ignoreCase), filter: ValueContainer(target))
    }

    /**
     * Returns a `Condition` that checks whether the value found at path `variable` is not equal
     * to the given `target`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the equality check should be done in a case-insensitive way; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - target: the target value to check against
     */
    static func doesNotEqual(ignoreCase: Bool, variable: JSONObjectPath, target: String) -> Self {
        Condition(variable: variable, operator: .notEquals(ignoreCase), filter: ValueContainer(target))
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable` is not equal
     * to the given `target`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the equality check should be done in a case-insensitive way; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - target: the target value to check against
     */
    static func doesNotEqual(ignoreCase: Bool, variable: String, target: String) -> Self {
        Condition(variable: variable, operator: .notEquals(ignoreCase), filter: ValueContainer(target))
    }

    /**
     * Returns a `Condition` that checks whether the value found at path `variable`, as a string,
     * contains the `string` within it.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - string: the target value to check against
     */
    static func contains(ignoreCase: Bool, variable: JSONObjectPath, string: String) -> Self {
        Condition(variable: variable, operator: .contains(ignoreCase), filter: ValueContainer(string))
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * contains the `string` within it.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - string: the target value to check against
     */
    static func contains(ignoreCase: Bool, variable: String, string: String) -> Self {
        Condition(variable: variable, operator: .contains(ignoreCase), filter: ValueContainer(string))
    }

    /**
     * Returns a `Condition` that checks whether the value found at path `variable`, as a string,
     * does not contain the `string` within it.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - string: the target value to check against
     */
    static func doesNotContain(ignoreCase: Bool, variable: JSONObjectPath, string: String) -> Self {
        Condition(variable: variable, operator: .notContains(ignoreCase), filter: ValueContainer(string))
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * does not contain the `string` within it.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - string: the target value to check against
     */
    static func doesNotContain(ignoreCase: Bool, variable: String, string: String) -> Self {
        Condition(variable: variable, operator: .notContains(ignoreCase), filter: ValueContainer(string))
    }

    /**
     * Returns a `Condition` that checks whether the value found at path `variable`, as a string,
     * starts with the given `prefix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - prefix: the target value to check against
     */
    static func startsWith(ignoreCase: Bool, variable: JSONObjectPath, prefix: String) -> Self {
        Condition(variable: variable, operator: .startsWith(ignoreCase), filter: ValueContainer(prefix))
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * starts with the given `prefix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - prefix: the target value to check against
     */
    static func startsWith(ignoreCase: Bool, variable: String, prefix: String) -> Self {
        Condition(variable: variable, operator: .startsWith(ignoreCase), filter: ValueContainer(prefix))
    }

    /**
     * Returns a `Condition` that checks whether the value found at path `variable`, as a string,
     * does not start with the given `prefix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - prefix: the target value to check against
     */
    static func doesNotStartWith(ignoreCase: Bool, variable: JSONObjectPath, prefix: String) -> Self {
        Condition(variable: variable, operator: .notStartsWith(ignoreCase), filter: ValueContainer(prefix))
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * does not start with the given `prefix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - prefix: the target value to check against
     */
    static func doesNotStartWith(ignoreCase: Bool, variable: String, prefix: String) -> Self {
        Condition(variable: variable, operator: .notStartsWith(ignoreCase), filter: ValueContainer(prefix))
    }

    /**
     * Returns a `Condition` that checks whether the value found at path `variable`, as a string,
     * ends with the given `suffix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - suffix: the target value to check against
     */
    static func endsWith(ignoreCase: Bool, variable: JSONObjectPath, suffix: String) -> Self {
        Condition(variable: variable, operator: .endsWith(ignoreCase), filter: ValueContainer(suffix))
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * ends with the given `suffix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - suffix: the target value to check against
     */
    static func endsWith(ignoreCase: Bool, variable: String, suffix: String) -> Self {
        Condition(variable: variable, operator: .endsWith(ignoreCase), filter: ValueContainer(suffix))
    }

    /**
     * Returns a `Condition` that checks whether the value found at path `variable`, as a string,
     * does not end with the given `suffix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - suffix: the target value to check against
     */
    static func doesNotEndWith(ignoreCase: Bool, variable: JSONObjectPath, suffix: String) -> Self {
        Condition(variable: variable, operator: .notEndsWith(ignoreCase), filter: ValueContainer(suffix))
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * does not end with the given `suffix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - suffix: the target value to check against
     */
    static func doesNotEndWith(ignoreCase: Bool, variable: String, suffix: String) -> Self {
        Condition(variable: variable, operator: .notEndsWith(ignoreCase), filter: ValueContainer(suffix))
    }

    /**
     * Returns a `Condition` that checks whether the value can be found at path `variable`.
     *
     * - Parameters:
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     */
    static func isDefined(variable: JSONObjectPath) -> Self {
        Condition(variable: variable, operator: .isDefined, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value can be found at key `variable`.
     *
     * - Parameters:
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     */
    static func isDefined(variable: String) -> Self {
        Condition(variable: variable, operator: .isDefined, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value can not be found at path `variable`.
     *
     * - Parameters:
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     */
    static func isNotDefined(variable: JSONObjectPath) -> Self {
        Condition(variable: variable, operator: .isNotDefined, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value can not be found at key `variable`.
     *
     * - Parameters:
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     */
    static func isNotDefined(variable: String) -> Self {
        Condition(variable: variable, operator: .isNotDefined, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value at path `variable` is considered to be "empty".
     *
     * "Empty" is considered as the following for the different supported input types:
     *  - `String.isEmpty`
     *  - `Array.isEmpty`
     *  - `Dictionary.isEmpty`
     *  - `value == NSNull()`
     *
     * Numeric values are always considered as not empty.
     *
     * - Parameters:
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     */
    static func isEmpty(variable: JSONObjectPath) -> Self {
        Condition(variable: variable, operator: .isEmpty, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value at key `variable` is considered to be "empty".
     *
     * "Empty" is considered as the following for the different supported input types:
     *  - `String.isEmpty`
     *  - `Array.isEmpty`
     *  - `Dictionary.isEmpty`
     *  - `value == NSNull()`
     *
     * Numeric values are always considered as not empty.
     *
     * - Parameters:
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     */
    static func isEmpty(variable: String) -> Self {
        Condition(variable: variable, operator: .isEmpty, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value at path `variable` is considered to be "not empty".
     *
     * "Not empty" is considered as the following for the different supported input types:
     *  - `!String.isEmpty`
     *  - `!Array.isEmpty`
     *  - `!Dictionary.isEmpty`
     *  - `value != NSNull()`
     *
     * Numeric values are always considered as not empty.
     *
     * - Parameters:
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     */
    static func isNotEmpty(variable: JSONObjectPath) -> Self {
        Condition(variable: variable, operator: .isNotEmpty, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value at key `variable` is considered to be "not empty".
     *
     * "Not empty" is considered as the following for the different supported input types:
     *  - `!String.isEmpty`
     *  - `!Array.isEmpty`
     *  - `!Dictionary.isEmpty`
     *  - `value != NSNull()`
     *
     * Numeric values are always considered as not empty.
     *
     * - Parameters:
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     */
    static func isNotEmpty(variable: String) -> Self {
        Condition(variable: variable, operator: .isNotEmpty, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the `Double` value found at path `variable`,
     * is greater than the `Double` value given by `number`
     *
     * - Parameters:
     *      - orEqual: `true` if numbers can also be equal; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - number: the target value to check against
     */
    static func isGreaterThan(orEqual: Bool, variable: JSONObjectPath, number: String) -> Self {
        Condition(variable: variable, operator: .greaterThan(orEqual), filter: ValueContainer(number))
    }

    /**
     * Returns a `Condition` that checks whether the `Double` value found at key `variable`,
     * is greater than the `Double` value given by `number`
     *
     * - Parameters:
     *      - orEqual: `true` if numbers can also be equal; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - number: the target value to check against
     */
    static func isGreaterThan(orEqual: Bool, variable: String, number: String) -> Self {
        Condition(variable: variable, operator: .greaterThan(orEqual), filter: ValueContainer(number))
    }

    /**
     * Returns a `Condition` that checks whether the `Double` value found at path `variable`,
     * is less than the `Double` value given by `number`
     *
     * - Parameters:
     *      - orEqual: `true` if numbers can also be equal; else `false`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - number: the target value to check against
     */
    static func isLessThan(orEqual: Bool, variable: JSONObjectPath, number: String) -> Self {
        Condition(variable: variable, operator: .lessThan(orEqual), filter: ValueContainer(number))
    }

    /**
     * Returns a `Condition` that checks whether the `Double` value found at key `variable`,
     * is less than the `Double` value given by `number`
     *
     * - Parameters:
     *      - orEqual: `true` if numbers can also be equal; else `false`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - number: the target value to check against
     */
    static func isLessThan(orEqual: Bool, variable: String, number: String) -> Self {
        Condition(variable: variable, operator: .lessThan(orEqual), filter: ValueContainer(number))
    }

    /**
     * Returns a `Condition` that checks whether the value found at path `variable`, as a string,
     * is matched by the given `regex`.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the path to the variable in the payload to extract the value from for the comparison
     *      - regex: the target regex to check against
     */
    static func regularExpression(variable: JSONObjectPath, regex: String) -> Self {
        Condition(variable: variable, operator: .regex, filter: ValueContainer(regex))
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * is matched by the given `regex`.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to the variable in the payload to extract the value from for the comparison
     *      - regex: the target regex to check against
     */
    static func regularExpression(variable: String, regex: String) -> Self {
        Condition(variable: variable, operator: .regex, filter: ValueContainer(regex))
    }
}
