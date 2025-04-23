//
//  Condition+Initializers.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 28/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

public extension Condition {
    /**
     * Returns a `Condition` that checks whether the value found at key `variable` is equal to
     * the given `target`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the equality check should be done in a case-insensitive way; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - target: the target value to check against
     */
    static func equals(ignoreCase: Bool, path: [String]? = nil, variable: String, target: String) -> Self {
        Condition(path: path, variable: variable, operator: .equals(ignoreCase), filter: target)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable` is not equal
     * to the given `target`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the equality check should be done in a case-insensitive way; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - target: the target value to check against
     */
    static func doesNotEqual(ignoreCase: Bool, path: [String]? = nil, variable: String, target: String) -> Self {
        Condition(path: path, variable: variable, operator: .notEquals(ignoreCase), filter: target)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * contains the `string` within it.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - string: the target value to check against
     */
    static func contains(ignoreCase: Bool, path: [String]? = nil, variable: String, string: String) -> Self {
        Condition(path: path, variable: variable, operator: .contains(ignoreCase), filter: string)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * does not contain the `string` within it.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - string: the target value to check against
     */
    static func doesNotContain(ignoreCase: Bool, path: [String]? = nil, variable: String, string: String) -> Self {
        Condition(path: path, variable: variable, operator: .notContains(ignoreCase), filter: string)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * starts with the given `prefix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - prefix: the target value to check against
     */
    static func startsWith(ignoreCase: Bool, path: [String]? = nil, variable: String, prefix: String) -> Self {
        Condition(path: path, variable: variable, operator: .startsWith(ignoreCase), filter: prefix)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * does not start with the given `prefix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - prefix: the target value to check against
     */
    static func doesNotStartWith(ignoreCase: Bool, path: [String]? = nil, variable: String, prefix: String) -> Self {
        Condition(path: path, variable: variable, operator: .notStartsWith(ignoreCase), filter: prefix)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * ends with the given `suffix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - suffix: the target value to check against
     */
    static func endsWith(ignoreCase: Bool, path: [String]? = nil, variable: String, suffix: String) -> Self {
        Condition(path: path, variable: variable, operator: .endsWith(ignoreCase), filter: suffix)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * does not end with the given `suffix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - suffix: the target value to check against
     */
    static func doesNotEndWith(ignoreCase: Bool, path: [String]? = nil, variable: String, suffix: String) -> Self {
        Condition(path: path, variable: variable, operator: .notEndsWith(ignoreCase), filter: suffix)
    }

    /**
     * Returns a `Condition` that checks whether the value can be found at key `variable`.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     */
    static func isDefined(path: [String]? = nil, variable: String) -> Self {
        Condition(path: path, variable: variable, operator: .isDefined, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value can not be found at key `variable`.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     */
    static func isNotDefined(path: [String]? = nil, variable: String) -> Self {
        Condition(path: path, variable: variable, operator: .isNotDefined, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value can be found at key `variable` and that
     * the value is considered "populated".
     *
     * "populated" is considered as the following for the different supported input types:
     *  - `!String.isEmpty`
     *  - `!Array.isEmpty`
     *  - `!Dictionary.isEmpty`
     *  - `value != nil`, `value != NSNull()`
     *
     * Numeric values are always considered as populated.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     */
    static func isPopulated(path: [String]? = nil, variable: String) -> Self {
        Condition(path: path, variable: variable, operator: .isPopulated, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value can be found at key `variable` and that
     * the value is considered "not-populated".
     *
     * "not-populated" is considered as the following for the different supported input types:
     *  - `String.isEmpty`
     *  - `Array.isEmpty`
     *  - `Dictionary.isEmpty`
     *  - `value == nil`, `value == NSNull()`
     *
     * Numeric values are always considered as populated.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     */
    static func isNotPopulated(path: [String]? = nil, variable: String) -> Self {
        Condition(path: path, variable: variable, operator: .isNotPopulated, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the `Decimal` value found at key `variable`,
     * is greater than the `Decimal` value given by `number`
     *
     * - Parameters:
     *      - orEqual: `true` if numbers can also be equal; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - number: the target value to check against
     */
    static func isGreaterThan(orEqual: Bool, path: [String]? = nil, variable: String, number: String) -> Self {
        Condition(path: path, variable: variable, operator: .greaterThan(orEqual), filter: number)
    }

    /**
     * Returns a `Condition` that checks whether the `Decimal` value found at key `variable`,
     * is less than the `Decimal` value given by `number`
     *
     * - Parameters:
     *      - orEqual: `true` if numbers can also be equal; else `false`
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - number: the target value to check against
     */
    static func isLessThan(orEqual: Bool, path: [String]? = nil, variable: String, number: String) -> Self {
        Condition(path: path, variable: variable, operator: .lessThan(orEqual), filter: number)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * is matched by the given `regex`.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     *      - regex: the target regex to check against
     */
    static func regularExpression(path: [String]? = nil, variable: String, regex: String) -> Self {
        Condition(path: path, variable: variable, operator: .regex, filter: regex)
    }

    /**
     * Returns a `Condition` that checks whether there is a badge found at key `variable`.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     */
    static func isBadgeAssigned(path: [String]? = nil, variable: String) -> Self {
        Condition(path: path, variable: variable, operator: .isBadgeAssigned, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether there is not a badge found at key `variable`.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the key to extract the value from for the comparison
     */
    static func isBadgeNotAssigned(path: [String]? = nil, variable: String) -> Self {
        Condition(path: path, variable: variable, operator: .isBadgeNotAssigned, filter: nil)
    }
}
