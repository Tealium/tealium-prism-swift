//
//  DataItemFormatter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 28/11/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A utility to represent `DataItem` in a human readable format.
class DataItemFormatter {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.positiveInfinitySymbol = "Infinity"
        formatter.negativeInfinitySymbol = "-Infinity"
        formatter.notANumberSymbol = "NaN"
        formatter.maximumFractionDigits = 16
        return formatter
    }()

    /**
     * Returns a string representation of the item.
     *
     * For arrays and objects, the JSON representation will be used instead (which may include scientific notation for numbers).
     * Root-level numbers are kept in non-scientific notation.
     * Root-level nulls and nils return nil.
     */
    static func format(dataItem: DataItem) -> String? {
        guard let value = dataItem.value, !(value is NSNull) else {
            return nil
        }
        if value is [String: Any] || value is [Any] {
            return try? AnyEncodable(value).serialize()
        } else if let number = dataItem.get(as: Double.self) {
            return format(double: number)
        } else {
            return String(describing: value)
        }
    }

    static func format(double: Double) -> String {
        // using custom formatter to get correct "Infinity" and "NaN" strings
        // as well as to remove fraction zeroes (1.0 -> 1) and disable scientific notation
        Self.numberFormatter.string(for: double) ?? String(describing: double)
    }

    static func number(from string: String) -> NSNumber? {
        Self.numberFormatter.number(from: string)
    }
}
