//
//  Condition+Matchable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

fileprivate extension DataItem {
    var isEmpty: Bool {
        if let array = getDataArray() {
            return array.isEmpty
        } else if let dictionary = getDataDictionary() {
            return dictionary.isEmpty
        } else if let value = value as? String {
            return value.isEmpty
        } else if value is NSNull {
            return true
        } else {
            return false
        }
    }

    func describeValue() -> String {
        guard let result = self.stringValue ?? self.value else {
            return "null"
        }
        return String(describing: result)
    }
}

extension Condition: Matchable {
    typealias ErrorKind = ConditionEvaluationError.Kind
    static let formatter = DataItemFormatter.self
    public func matches(payload: DataObject) throws(ConditionEvaluationError) -> Bool {
        do throws(ErrorKind) {
            guard let dataItem = payload.extractDataItem(path: variable.path) else {
                switch self.operator {
                case .isDefined:
                    return false
                case .isNotDefined:
                    return true
                default:
                    throw .missingDataItem
                }
            }
            return switch self.operator {
            case .isDefined:
                true
            case .isNotDefined:
                false
            case .isEmpty:
                dataItem.isEmpty
            case .isNotEmpty:
                !dataItem.isEmpty
            case .equals(let ignoreCase):
                try equals(dataItem: dataItem, ignoreCase: ignoreCase)
            case .notEquals(let ignoreCase):
                try !equals(dataItem: dataItem, ignoreCase: ignoreCase)
            case .greaterThan(let orEqual):
                try numbersMatch(dataItem: dataItem, orEqual: orEqual) { $0 > $1 }
            case .lessThan(let orEqual):
                try numbersMatch(dataItem: dataItem, orEqual: orEqual) { $0 < $1 }
            case .contains(let ignoreCase):
                try stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { $0.contains($1) }
            case .notContains(let ignoreCase):
                try stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { !$0.contains($1) }
            case .endsWith(let ignoreCase):
                try stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { $0.hasSuffix($1) }
            case .notEndsWith(let ignoreCase):
                try stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { !$0.hasSuffix($1) }
            case .startsWith(let ignoreCase):
                try stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { $0.hasPrefix($1) }
            case .notStartsWith(let ignoreCase):
                try stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { !$0.hasPrefix($1) }
            case .regex:
                try stringsMatch(dataItem: dataItem, ignoreCase: false) {
                    $0.range(of: $1, options: .regularExpression) != nil
                }
            }
        } catch {
            throw ConditionEvaluationError(kind: error, condition: self)
        }
    }

    private func equals(dataItem: DataItem, ignoreCase: Bool) throws(ErrorKind) -> Bool {
        var filter = try requireFilter()
        if let double = dataItem.get(as: Double.self),
           // we want equals to return true in case the item is Double.nan and the filter is "NaN"
           // that is why we don't call `convertToDouble` here - to skip to the string equality check
           let value = Self.formatter.number(from: filter)?.doubleValue {
            return double == value
        }
        var input = try stringify(dataItem)
        if ignoreCase {
            input = input.lowercased()
            filter = filter.lowercased()
        }
        return input == filter
    }

    private func stringsMatch(dataItem: DataItem, ignoreCase: Bool, _ predicate: (String, String) -> Bool) throws(ErrorKind) -> Bool {
        var filter = try requireFilter()
        var string = try stringify(dataItem)
        if ignoreCase {
            string = string.lowercased()
            filter = filter.lowercased()
        }
        return predicate(string, filter)
    }

    private func numbersMatch(dataItem: DataItem, orEqual: Bool, _ predicate: (Double, Double) -> Bool) throws(ErrorKind) -> Bool {
        let filter = try requireFilter()
        let value = try convertToDouble(DataItem(value: filter), source: "Filter")
        let number = if let number = dataItem.get(as: Double.self) {
            number
        } else {
            try convertToDouble(dataItem, source: "DataItem")
        }
        if number == value {
            return orEqual
        }
        return predicate(number, value)
    }

    private func requireFilter() throws(ErrorKind) -> String {
        guard let filter else {
            throw .missingFilter
        }
        return filter.value
    }

    private func convertToDouble(_ dataItem: DataItem, source: String) throws(ErrorKind) -> Double {
        guard let numString = dataItem.get(as: String.self), !numString.isEmpty else {
            throw .numberParsingError(parsing: dataItem.describeValue(), source: source)
        }
        if numString == "NaN" {
            return Double.nan
        }
        guard let number = Self.formatter.number(from: numString)?.doubleValue else {
            throw .numberParsingError(parsing: numString, source: source)
        }
        return number
    }

    private func stringify(_ value: DataItem) throws(ErrorKind) -> String {
        if let array = value.getDataArray() {
            do {
                return try array.map { item throws(ErrorKind) in
                    try stringify(item)
                }.joined(separator: ",")
            } catch let .operationNotSupportedFor(typeFound) {
                throw .operationNotSupportedFor("Array containing: \(typeFound)")
            }
        } else if let dictionary = value.getDataDictionary() {
            throw .operationNotSupportedFor("\(type(of: dictionary))")
        } else {
            return Self.formatter.format(dataItem: value) ?? "null"
        }
    }
}
