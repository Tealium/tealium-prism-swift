//
//  LenientConverters.swift
//  tealium-prism
//
//  Created by Den Guzov on 11/02/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A collection of lenient converters that can handle type mismatches in JSON data.
///
/// These converters attempt multiple conversion strategies when the actual type
/// in JSON differs from the expected type. They follow a fail-safe pattern:
/// returning `nil` for invalid or non-representable values rather than crashing or
/// producing corrupted data.
///
/// Edge cases handled:
/// - Integer overflow: NaN values return `nil`; values outside `Int.min...Int.max` (including infinities) are clamped to `Int.min`/`Int.max`
/// - Special float values: `Double.nan` is treated as invalid; `Double.infinity` and `-Double.infinity` are clamped in integer conversions
/// - String parsing: Invalid formats return `nil` rather than crashing
/// - Type mismatches: Missing or incompatible types return `nil`
///
/// Example usage:
/// ```swift
/// let payload: DataObject = ...
/// let timeout = payload.getConvertible(key: "timeout", converter: LenientConverters.double)
/// let retryCount = payload.getConvertible(key: "retryCount", converter: LenientConverters.int)
/// let isEnabled = payload.getConvertible(key: "isEnabled", converter: LenientConverters.bool)
/// ```
public enum LenientConverters {

    // MARK: - Double Converter
    /// A lenient converter to `Double` values.
    ///
    /// This converter attempts the following conversions in order:
    /// 1. Direct extraction as `Double`
    /// 2. Extraction as `String` and parsing via `DataItemFormatter` (uses en_US_POSIX locale)
    public static let double: any DataItemConverter<Double> = DoubleConverter()

    // MARK: - Int Converter
    /// A lenient converter to `Int` values.
    ///
    /// This converter attempts the following conversions in order:
    /// 1. Direct extraction as `Int` (uses NSNumber's intValue which clamps to Int.min/Int.max and truncates decimals)
    /// 2. Extraction as `String` and parsing via `DataItemFormatter` (truncates decimal part)
    ///
    /// Returns `nil` for values that:
    /// - Cannot be parsed as numbers
    /// - Note: Out-of-bounds Double values are clamped to Int.min/Int.max (NSNumber behavior)
    public static let int: any DataItemConverter<Int> = IntConverter()

    // MARK: - Bool Converter
    /// A lenient converter to `Bool` values.
    ///
    /// This converter attempts the following conversions in order:
    /// 1. Direct extraction as `Bool`
    /// 2. Extraction as `String` and parsing common boolean representations:
    ///    - "true", "yes", "1" → `true`
    ///    - "false", "no", "0" → `false`
    ///    (case-insensitive)
    /// 3. Extraction as whole number where 0 is `false` and 1 is `true`
    ///    - Note: Decimal numbers (e.g., 1.5) and integers other than 0 or 1 will return `nil`
    ///
    /// Returns `nil` for values that:
    /// - Any other strings non-conforming to the rule above
    /// - Any numbers other than 0 or 1
    public static let bool: any DataItemConverter<Bool> = BoolConverter()

    // MARK: - String Converter
    /// A lenient converter to `String` values.
    ///
    /// This converter attempts the following conversions in order:
    /// 1. Direct extraction as `String`
    /// 2. Conversion of `Bool` to "true" or "false"
    /// 3. Conversion of numeric types (`Double`, `Int`) to `String` using `DataItemFormatter`
    ///    - Special values: `Double.nan` → `"NaN"`, `Double.infinity` → `"Infinity"`
    ///    - Whole numbers: 1.0 → `"1"` (removes unnecessary ".0" suffix)
    ///    - Disables scientific notation for better readability
    public static let string: any DataItemConverter<String> = StringConverter()
}
