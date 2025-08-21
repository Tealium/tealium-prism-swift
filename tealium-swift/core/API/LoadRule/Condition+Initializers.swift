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
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - target: the target value to check against
     */
    static func equals(ignoreCase: Bool, variable: VariableAccessor, target: String) -> Self {
        Condition(variable: variable, operator: .equals(ignoreCase), filter: target)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable` is not equal
     * to the given `target`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the equality check should be done in a case-insensitive way; else `false`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - target: the target value to check against
     */
    static func doesNotEqual(ignoreCase: Bool, variable: VariableAccessor, target: String) -> Self {
        Condition(variable: variable, operator: .notEquals(ignoreCase), filter: target)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * contains the `string` within it.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - string: the target value to check against
     */
    static func contains(ignoreCase: Bool, variable: VariableAccessor, string: String) -> Self {
        Condition(variable: variable, operator: .contains(ignoreCase), filter: string)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * does not contain the `string` within it.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - string: the target value to check against
     */
    static func doesNotContain(ignoreCase: Bool, variable: VariableAccessor, string: String) -> Self {
        Condition(variable: variable, operator: .notContains(ignoreCase), filter: string)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * starts with the given `prefix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - prefix: the target value to check against
     */
    static func startsWith(ignoreCase: Bool, variable: VariableAccessor, prefix: String) -> Self {
        Condition(variable: variable, operator: .startsWith(ignoreCase), filter: prefix)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * does not start with the given `prefix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - prefix: the target value to check against
     */
    static func doesNotStartWith(ignoreCase: Bool, variable: VariableAccessor, prefix: String) -> Self {
        Condition(variable: variable, operator: .notStartsWith(ignoreCase), filter: prefix)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * ends with the given `suffix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - suffix: the target value to check against
     */
    static func endsWith(ignoreCase: Bool, variable: VariableAccessor, suffix: String) -> Self {
        Condition(variable: variable, operator: .endsWith(ignoreCase), filter: suffix)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * does not end with the given `suffix`.
     *
     * - Parameters:
     *      - ignoreCase: `true` if the comparison should be done in a case-insensitive way; else `false`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - suffix: the target value to check against
     */
    static func doesNotEndWith(ignoreCase: Bool, variable: VariableAccessor, suffix: String) -> Self {
        Condition(variable: variable, operator: .notEndsWith(ignoreCase), filter: suffix)
    }

    /**
     * Returns a `Condition` that checks whether the value can be found at key `variable`.
     *
     * - Parameters:
     *      - variable: the variable in the data layer to extract the value from for the comparison
     */
    static func isDefined(variable: VariableAccessor) -> Self {
        Condition(variable: variable, operator: .isDefined, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the value can not be found at key `variable`.
     *
     * - Parameters:
     *      - variable: the variable in the data layer to extract the value from for the comparison
     */
    static func isNotDefined(variable: VariableAccessor) -> Self {
        Condition(variable: variable, operator: .isNotDefined, filter: nil)
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
     *      - variable: the variable in the data layer to extract the value from for the comparison
     */
    static func isPopulated(variable: VariableAccessor) -> Self {
        Condition(variable: variable, operator: .isPopulated, filter: nil)
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
     *      - variable: the variable in the data layer to extract the value from for the comparison
     */
    static func isNotPopulated(variable: VariableAccessor) -> Self {
        Condition(variable: variable, operator: .isNotPopulated, filter: nil)
    }

    /**
     * Returns a `Condition` that checks whether the `Double` value found at key `variable`,
     * is greater than the `Double` value given by `number`
     *
     * - Parameters:
     *      - orEqual: `true` if numbers can also be equal; else `false`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - number: the target value to check against
     */
    static func isGreaterThan(orEqual: Bool, variable: VariableAccessor, number: String) -> Self {
        Condition(variable: variable, operator: .greaterThan(orEqual), filter: number)
    }

    /**
     * Returns a `Condition` that checks whether the `Double` value found at key `variable`,
     * is less than the `Double` value given by `number`
     *
     * - Parameters:
     *      - orEqual: `true` if numbers can also be equal; else `false`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - number: the target value to check against
     */
    static func isLessThan(orEqual: Bool, variable: VariableAccessor, number: String) -> Self {
        Condition(variable: variable, operator: .lessThan(orEqual), filter: number)
    }

    /**
     * Returns a `Condition` that checks whether the value found at key `variable`, as a string,
     * is matched by the given `regex`.
     *
     * - Parameters:
     *      - path: optional list of keys that form the access to sub-objects when accessing the `variable`
     *      - variable: the variable in the data layer to extract the value from for the comparison
     *      - regex: the target regex to check against
     */
    static func regularExpression(variable: VariableAccessor, regex: String) -> Self {
        Condition(variable: variable, operator: .regex, filter: regex)
    }
}
