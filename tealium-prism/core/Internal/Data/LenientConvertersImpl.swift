//
//  LenientConvertersImpl.swift
//  tealium-prism
//
//  Created by Den Guzov on 16/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

struct LenientDoubleConverter: DataItemConverter {
    typealias Convertible = Double

    func convert(dataItem: DataItem) -> Double? {
        // Try direct conversion
        if let value = dataItem.get(as: Double.self) {
            return value
        }
        // Try string conversion via DataItemFormatter
        guard let stringValue = dataItem.get(as: String.self) else {
            return nil
        }
        guard stringValue != "NaN" else {
            return .nan
        }
        return DataItemFormatter.number(from: stringValue)?.doubleValue
    }
}

struct LenientIntConverter: DataItemConverter {
    typealias Convertible = Int

    func convert(dataItem: DataItem) -> Int? {
        // Direct Int conversion (uses NSNumber.intValue with clamping)
        if let intValue = dataItem.get(as: Int.self) {
            return intValue
        }
        // String conversion via DataItemFormatter
        guard let stringValue = dataItem.get(as: String.self) else {
            return nil
        }
        return DataItemFormatter.number(from: stringValue)?.intValue
    }
}

struct LenientBoolConverter: DataItemConverter {
    typealias Convertible = Bool

    func convert(dataItem: DataItem) -> Bool? {
        // Try direct conversion
        if let value = dataItem.get(as: Bool.self) {
            return value
        }
        // Try string conversion with common boolean representations
        if let stringValue = dataItem.get(as: String.self) {
            let lowercased = stringValue.lowercased().trimmingCharacters(in: .whitespaces)
            switch lowercased {
            case "true", "yes", "1":
                return true
            case "false", "no", "0":
                return false
            default:
                return nil
            }
        }
        // Try numeric conversion, but only for 0 and 1
        guard let doubleValue = dataItem.get(as: Double.self) else {
            return nil
        }
        switch doubleValue {
        case 0.0:
            return false
        case 1.0:
            return true
        default:
            return nil
        }
    }
}

struct LenientStringConverter: DataItemConverter {
    typealias Convertible = String

    func convert(dataItem: DataItem) -> String? {
        // Try direct conversion
        if let value = dataItem.get(as: String.self) {
            return value
        }
        // Try bool conversion
        if let boolValue = dataItem.get(as: Bool.self) {
            return boolValue ? "true" : "false"
        }
        // Try double conversion - reuse DataItemFormatter for proper formatting
        if let doubleValue = dataItem.get(as: Double.self) {
            return DataItemFormatter.format(double: doubleValue)
        }
        return nil
    }
}
