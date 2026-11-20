//
//  DataItemExtractor+FailableExtraction.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 10/11/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Helpers for reading values from a `DataItemExtractor`, throwing an `ExtractionError` when they can't be read.
///
/// A `Command` can call them directly: when the SDK runs it, a thrown `ExtractionError` is reported as `CommandError.invalidPayload`.
///
/// - The `require` helpers treat an explicit JSON `null` as missing, with the exception of `requireDataItem`.
/// - The `optional` helpers return `nil` for both an absent and an explicit `null` value.
public extension DataItemExtractor where Self: ~Copyable {

    /// Returns the `DataItem` at the path of the given parameter.
    ///
    /// An explicit JSON `null` is returned as a `null` `DataItem`, not treated as missing,
    /// so that callers can tell "set to null" apart from "absent".
    ///
    /// - parameter parameter: The parameter whose path is looked up in this extractor.
    /// - returns: The `DataItem` found at the parameter's path.
    /// - throws: `ExtractionError.missing` if there is no `DataItem` at the parameter's path.
    func requireDataItem(_ parameter: some JSONObjectPathConvertible) throws(ExtractionError) -> DataItem {
        guard let item = extractDataItem(path: parameter.path) else {
            throw .missing(key: parameter.path.render())
        }
        return item
    }

    /// Returns the dictionary at the path of the given parameter.
    ///
    /// - parameter parameter: The parameter whose path is looked up in this extractor.
    /// - returns: The `[String: DataItem]` found at the parameter's path.
    /// - throws: `ExtractionError.missing` if there is no `DataItem` at the parameter's path or it is an explicit `null`,
    /// or `ExtractionError.typeMismatch` if the `DataItem` is not a dictionary.
    func requireDataDictionary(_ parameter: some JSONObjectPathConvertible) throws(ExtractionError) -> [String: DataItem] {
        guard let value = try optionalDataDictionary(parameter) else {
            throw .missing(key: parameter.path.render())
        }
        return value
    }

    /// Returns the value at the path of the given parameter, converted with the given converter.
    ///
    /// - parameters:
    ///   - parameter: The parameter whose path is looked up in this extractor.
    ///   - converter: The converter used to turn the `DataItem` into the requested type.
    /// - returns: The converted value.
    /// - throws: `ExtractionError.missing` if there is no `DataItem` at the parameter's path or it is an explicit `null`,
    /// or `ExtractionError.typeMismatch` if the converter can't convert the `DataItem`.
    func require<T>(_ parameter: some JSONObjectPathConvertible, converter: any DataItemConverter<T>) throws(ExtractionError) -> T {
        guard let value = try optional(parameter, converter: converter) else {
            throw .missing(key: parameter.path.render())
        }
        return value
    }

    /// Returns the `String` at the path of the given parameter, requiring it not to be blank (empty or whitespace only).
    ///
    /// - parameters:
    ///   - parameter: The parameter whose path is looked up in this extractor.
    ///   - converter: The converter used to turn the `DataItem` into a `String`.
    /// - returns: The converted value, untrimmed.
    /// - throws: `ExtractionError.missing` if there is no `DataItem` at the parameter's path or it is an explicit `null`,
    /// `ExtractionError.typeMismatch` if the converter can't convert the `DataItem`,
    /// or `ExtractionError.empty` if the value is blank (empty or whitespace only).
    func requireNonBlank(_ parameter: some JSONObjectPathConvertible, converter: any DataItemConverter<String>) throws(ExtractionError) -> String {
        let value = try require(parameter, converter: converter)
        guard !value.isBlank else {
            throw .empty(key: parameter.path.render())
        }
        return value
    }

    /// Returns the value mapped to the `String` at the path of the given parameter.
    ///
    /// The `String` is read with ``LenientConverters/string``, trimmed,
    /// and matched case-insensitively against the keys of `values`. Keys that differ only by case are ambiguous, so avoid them.
    ///
    /// - parameters:
    ///   - parameter: The parameter whose path is looked up in this extractor.
    ///   - values: The accepted strings and the values they map to.
    ///   The keys, sorted case-insensitively, are listed in the error reason.
    /// - returns: The value mapped to the matching key.
    /// - throws: `ExtractionError.missing` if there is no `DataItem` at the parameter's path or it is an explicit `null`,
    /// `ExtractionError.typeMismatch` if the `DataItem` can't be read as a `String`,
    /// `ExtractionError.empty` if the `String` is blank (empty or whitespace only),
    /// or `ExtractionError.invalidValue` if it matches none of the keys, with the reason "expected one of " followed by the sorted keys.
    func requireOneOf<T>(_ parameter: some JSONObjectPathConvertible, values: [String: T]) throws(ExtractionError) -> T {
        let string = try require(parameter, converter: LenientConverters.string)
        guard !string.isBlank else {
            throw .empty(key: parameter.path.render())
        }
        return try match(string, in: values, parameter: parameter)
    }

    /// Returns the value mapped to the `String` at the path of the given parameter, or `nil` if there is nothing to match.
    ///
    /// Matching works as in ``requireOneOf(_:values:)``.
    ///
    /// - parameters:
    ///   - parameter: The parameter whose path is looked up in this extractor.
    ///   - values: The accepted strings and the values they map to.
    ///   The keys, sorted case-insensitively, are listed in the error reason.
    /// - returns: The value mapped to the matching key, or `nil` if the parameter is absent, an explicit `null` or blank (empty or whitespace only).
    /// - throws: `ExtractionError.typeMismatch` if the `DataItem` can't be read as a `String`,
    /// or `ExtractionError.invalidValue` if it is not blank and matches none of the keys, with the reason "expected one of " followed by the sorted keys.
    func optionalOneOf<T>(_ parameter: some JSONObjectPathConvertible, values: [String: T]) throws(ExtractionError) -> T? {
        guard let string = try optional(parameter, converter: LenientConverters.string), !string.isBlank else {
            return nil
        }
        return try match(string, in: values, parameter: parameter)
    }

    /// Returns the value at the path of the given parameter, converted with the given converter,
    /// or `nil` if the parameter is absent or an explicit JSON `null`.
    ///
    /// - parameters:
    ///   - parameter: The parameter whose path is looked up in this extractor.
    ///   - converter: The converter used to turn the `DataItem` into the requested type.
    /// - returns: The converted value, or `nil` if there is no value at the parameter's path or it is `null`.
    /// - throws: `ExtractionError.typeMismatch` if the parameter is present but the converter can't convert it.
    func optional<T>(_ parameter: some JSONObjectPathConvertible, converter: any DataItemConverter<T>) throws(ExtractionError) -> T? {
        guard let item = extractDataItem(path: parameter.path), !(item.value is NSNull) else {
            return nil
        }
        guard let value = item.getConvertible(converter: converter) else {
            throw .typeMismatch(key: parameter.path.render(), expectedType: "\(T.self)")
        }
        return value
    }

    /// Returns the dictionary at the path of the given parameter,
    /// or `nil` if the parameter is absent or an explicit JSON `null`.
    ///
    /// - parameter parameter: The parameter whose path is looked up in this extractor.
    /// - returns: The `[String: DataItem]` found at the parameter's path, or `nil` if there is none or it is `null`.
    /// - throws: `ExtractionError.typeMismatch` if the parameter is present but is not a dictionary.
    func optionalDataDictionary(_ parameter: some JSONObjectPathConvertible) throws(ExtractionError) -> [String: DataItem]? {
        guard let item = extractDataItem(path: parameter.path), !(item.value is NSNull) else {
            return nil
        }
        guard let value = item.getDataDictionary() else {
            throw .typeMismatch(key: parameter.path.render(), expectedType: "\([String: DataItem].self)")
        }
        return value
    }

    private func match<T>(_ string: String, in values: [String: T], parameter: some JSONObjectPathConvertible) throws(ExtractionError) -> T {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = values.first(where: { $0.key.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            // A non-localized compare keeps the message the same on every device locale.
            let keys = values.keys.sorted { $0.caseInsensitiveCompare($1) == .orderedAscending }
            throw .invalidValue(key: parameter.path.render(), reason: "expected one of \(keys.joined(separator: ", "))")
        }
        return match.value
    }
}
