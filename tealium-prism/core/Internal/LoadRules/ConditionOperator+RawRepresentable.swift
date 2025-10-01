//
//  Condition+RawRepresentable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension Condition.Operator: RawRepresentable {
    public typealias RawValue = String
    typealias Const = ConditionOperators

    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case Const.equals: self = .equals(false)
        case Const.equalsIgnoreCase: self = .equals(true)
        case Const.startsWith: self = .startsWith(false)
        case Const.startsWithIgnoreCase: self = .startsWith(true)
        case Const.doesNotStartWith: self = .notStartsWith(false)
        case Const.doesNotStartWithIgnoreCase: self = .notStartsWith(true)
        case Const.doesNotEqual: self = .notEquals(false)
        case Const.doesNotEqualIgnoreCase: self = .notEquals(true)
        case Const.endsWith: self = .endsWith(false)
        case Const.endsWithIgnoreCase: self = .endsWith(true)
        case Const.doesNotEndWith: self = .notEndsWith(false)
        case Const.doesNotEndWithIgnoreCase: self = .notEndsWith(true)
        case Const.contains: self = .contains(false)
        case Const.containsIgnoreCase: self = .contains(true)
        case Const.doesNotContain: self = .notContains(false)
        case Const.doesNotContainIgnoreCase: self = .notContains(true)
        case Const.defined: self = .isDefined
        case Const.notDefined: self = .isNotDefined
        case Const.empty: self = .isEmpty
        case Const.notEmpty: self = .isNotEmpty
        case Const.greaterThan: self = .greaterThan(false)
        case Const.greaterThanEqualTo: self = .greaterThan(true)
        case Const.lessThan: self = .lessThan(false)
        case Const.lessThanEqualTo: self = .lessThan(true)
        case Const.regularExpression: self = .regex
        default:
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .isDefined: Const.defined
        case .isNotDefined: Const.notDefined
        case .isEmpty: Const.empty
        case .isNotEmpty: Const.notEmpty
        case .equals(let ignoreCase):
            ignoreCase ? Const.equalsIgnoreCase : Const.equals
        case .notEquals(let ignoreCase):
            ignoreCase ? Const.doesNotEqualIgnoreCase : Const.doesNotEqual
        case .greaterThan(let orEqual): orEqual ? Const.greaterThanEqualTo : Const.greaterThan
        case .lessThan(let orEqual): orEqual ? Const.lessThanEqualTo : Const.lessThan
        case .contains(let ignoreCase):
            ignoreCase ? Const.containsIgnoreCase : Const.contains
        case .notContains(let ignoreCase):
            ignoreCase ? Const.doesNotContainIgnoreCase : Const.doesNotContain
        case .endsWith(let ignoreCase):
            ignoreCase ? Const.endsWithIgnoreCase : Const.endsWith
        case .notEndsWith(let ignoreCase):
            ignoreCase ? Const.doesNotEndWithIgnoreCase : Const.doesNotEndWith
        case .startsWith(let ignoreCase):
            ignoreCase ? Const.startsWithIgnoreCase : Const.startsWith
        case .notStartsWith(let ignoreCase):
            ignoreCase ? Const.doesNotStartWithIgnoreCase : Const.doesNotStartWith
        case .regex: Const.regularExpression
        }
    }
}
