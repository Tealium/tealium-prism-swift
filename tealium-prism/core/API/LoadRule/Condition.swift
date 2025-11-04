//
//  Condition.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// A Condition that can be used to verify the matching to a payload.
public struct Condition: Equatable {
    /// The operator used to evaluate a condition against a variable.
    public enum Operator: Equatable {
        /// An operator that matches if the variable is defined.
        case isDefined
        /// An operator that matches if the variable is not defined.
        case isNotDefined
        /// An operator that matches if the variable is considered to be empty.
        case isEmpty
        /// An operator that matches if the variable is considered not to be empty.
        case isNotEmpty
        /// An operator that matches if the variable is equal to the filter. Numeric comparison is attempted first,
        /// and then falls back to string equality if either the `DataItem` or filter cannot be parsed as a `Double`.
        /// - parameter ignoreCase: If true the equality check is case insensitive.
        case equals(_ ignoreCase: Bool)
        /// An operator that matches if the variable is not equal to the filter. Numeric comparison is attempted first,
        /// and then falls back to string equality if either the `DataItem` or filter cannot be parsed as a `Double`.
        /// - parameter ignoreCase: If true the equality check is case insensitive.
        case notEquals(_ ignoreCase: Bool)
        /// An operator that matches if the numeric variable is greater than filter. Both are converted to `Double`.
        /// - parameter orEqual: If true the comparison returns true for equal as well.
        case greaterThan(_ orEqual: Bool)
        /// An operator that matches if the numeric variable is less than filter. Both are converted to `Double`.
        /// - parameter orEqual: If true the comparison returns true for equal as well.
        case lessThan(_ orEqual: Bool)
        /// An operator that matches if the variable, converted to a string, contains the filter.
        /// - parameter ignoreCase: If true the contains check is case insensitive.
        case contains(_ ignoreCase: Bool)
        /// An operator that matches if the variable, converted to a string, does not contain the filter.
        /// - parameter ignoreCase: If true the contains check is case insensitive.
        case notContains(_ ignoreCase: Bool)
        /// An operator that matches if the variable, converted to a string, ends with the filter.
        /// - parameter ignoreCase: If true the endsWith check is case insensitive.
        case endsWith(_ ignoreCase: Bool)
        /// An operator that matches if the variable, converted to a string, doesn't end with the filter.
        /// - parameter ignoreCase: If true the endsWith check is case insensitive.
        case notEndsWith(_ ignoreCase: Bool)
        /// An operator that matches if the variable, converted to a string, starts with the filter.
        /// - parameter ignoreCase: If true the startsWith check is case insensitive.
        case startsWith(_ ignoreCase: Bool)
        /// An operator that matches if the variable, converted to a string, doesn't start with the filter.
        /// - parameter ignoreCase: If true the startWith check is case insensitive.
        case notStartsWith(_ ignoreCase: Bool)
        /**
         * An operator that matches using a regex.
         *
         * The regex needs to follow the `NSRegularExpression` format:
         * https://developer.apple.com/documentation/foundation/nsregularexpression
         */
        case regex
    }
    /// The reference to an object in the payload
    let variable: ReferenceContainer
    /// The operator used to match this condition.
    let `operator`: Operator
    /**
     * The optional parameter used for some of the operators.
     *
     * Required for:
     * equals, notEquals, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual,
     * contains, notContains, endsWith, notEndsWith, startsWith, notStartsWith, regex.
     *
     * Ignored for:
     * isDefined, isNotDefined, isEmpty, isNotEmpty.
     */
    let filter: ValueContainer?

    init(variable: ReferenceContainer, operator: Operator, filter: ValueContainer?) {
        self.variable = variable
        self.operator = `operator`
        self.filter = filter
    }

    init(variable: JSONObjectPath, operator: Operator, filter: ValueContainer?) {
        self.init(variable: ReferenceContainer(path: variable), operator: `operator`, filter: filter)
    }

    init(variable: String, operator: Operator, filter: ValueContainer?) {
        self.init(variable: ReferenceContainer(key: variable), operator: `operator`, filter: filter)
    }
}
