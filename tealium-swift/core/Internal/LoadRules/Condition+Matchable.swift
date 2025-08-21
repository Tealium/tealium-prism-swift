//
//  Condition+Matchable.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension DataItem {
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
}

extension Condition: Matchable {
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.positiveInfinitySymbol = "Infinity"
        formatter.negativeInfinitySymbol = "-Infinity"
        formatter.notANumberSymbol = "NaN"
        return formatter
    }()
    public func matches(payload: DataObject) -> Bool {
        guard let dataItem = extractValue(from: payload) else {
            return self.operator == .isNotDefined
        }

        return switch self.operator {
        case .isDefined:
            true
        case .isNotDefined:
            false
        case .isPopulated:
            !dataItem.isEmpty
        case .isNotPopulated:
            dataItem.isEmpty
        case .equals(let ignoreCase):
            equals(dataItem: dataItem, ignoreCase: ignoreCase)
        case .notEquals(let ignoreCase):
            notEquals(dataItem: dataItem, ignoreCase: ignoreCase)
        case .greaterThan(let orEqual):
            numbersMatch(dataItem: dataItem, orEqual: orEqual) { $0 > $1 }
        case .lessThan(let orEqual):
            numbersMatch(dataItem: dataItem, orEqual: orEqual) { $0 < $1 }
        case .contains(let ignoreCase):
            stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { $0.contains($1) }
        case .notContains(let ignoreCase):
            stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { !$0.contains($1) }
        case .endsWith(let ignoreCase):
            stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { $0.hasSuffix($1) }
        case .notEndsWith(let ignoreCase):
            stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { !$0.hasSuffix($1) }
        case .startsWith(let ignoreCase):
            stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { $0.hasPrefix($1) }
        case .notStartsWith(let ignoreCase):
            stringsMatch(dataItem: dataItem, ignoreCase: ignoreCase) { !$0.hasPrefix($1) }
        case .regex:
            stringsMatch(dataItem: dataItem, ignoreCase: false) {
                $0.range(of: $1, options: .regularExpression) != nil
            }
        }
    }

    private func equals(dataItem: DataItem, filter: String, ignoreCase: Bool) -> Bool {
        if let double = dataItem.get(as: Double.self),
           let value = Self.formatter.number(from: filter)?.doubleValue {
            return double == value
        }
        var input = stringify(dataItem.toDataInput())
        var filter = filter
        if ignoreCase {
            input = input.lowercased()
            filter = filter.lowercased()
        }
        return input == filter
    }

    private func notEquals(dataItem: DataItem, ignoreCase: Bool) -> Bool {
        guard let filter, !dataItem.isDictionary else {
            return false
        }
        return !equals(dataItem: dataItem, filter: filter, ignoreCase: ignoreCase)
    }

    private func equals(dataItem: DataItem, ignoreCase: Bool) -> Bool {
        guard let filter, !dataItem.isDictionary else {
            return false
        }
        return equals(dataItem: dataItem, filter: filter, ignoreCase: ignoreCase)
    }

    private func stringsMatch(dataItem: DataItem, ignoreCase: Bool, _ predicate: (String, String) -> Bool) -> Bool {
        guard var filter, !dataItem.isDictionary else {
            return false
        }
        let input = dataItem.toDataInput()
        var string = stringify(input)
        if ignoreCase {
            string = string.lowercased()
            filter = filter.lowercased()
        }
        return predicate(string, filter)
    }

    private func numbersMatch(dataItem: DataItem, orEqual: Bool, _ predicate: (Double, Double) -> Bool) -> Bool {
        guard let filter,
              !dataItem.isDictionary,
              let value = Self.formatter.number(from: filter)?.doubleValue,
              let number = dataItem.get(as: Double.self)
                ?? convertToDouble(dataItem, using: Self.formatter) else {
            return false
        }
        if number == value {
            return orEqual
        }
        return predicate(number, value)
    }

    private func convertToDouble(_ dataItem: DataItem, using formatter: NumberFormatter) -> Double? {
        guard let numString = dataItem.get(as: String.self), !numString.isEmpty else {
            return nil
        }
        return formatter.number(from: numString)?.doubleValue
    }

    private func extractValue(from payload: DataObject) -> DataItem? {
        guard let path = self.path else {
            return payload.getDataItem(key: variable)
        }
        var current: DataObject = payload
        for component in path {
            guard let container = current.getDataDictionary(key: component) else {
                return nil
            }
            current = container.toDataObject()
        }
        return current.getDataItem(key: variable)
    }

    private func stringify<DataInput>(_ value: DataInput) -> String {
        if value is NSNull {
            return "null"
        } else if let array = value as? [DataInput] {
            return array.map({ stringify($0) }).joined(separator: ",")
        } else {
            return String(describing: value)
        }
    }
}
