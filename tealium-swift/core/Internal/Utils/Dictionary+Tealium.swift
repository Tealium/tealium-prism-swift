//
//  Dictionary+Tealium.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

/// Allows use of plus operator for array reduction calls.
func + <Key, Value>(lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
    var result = lhs
    rhs.forEach { result[$0] = $1 }
    return result
}

/// Extend the use of += operators to dictionaries.
func += <K, V>(left: inout [K: V], right: [K: V]) {
    for (key, value) in right {
        left.updateValue(value, forKey: key)
    }
}

public extension Dictionary {
    @inlinable
    init<S>(_ keysAndValues: S, prefersFirst: Bool) where S: Sequence, S.Element == (Key, Value) {
        self.init(keysAndValues) { prefersFirst ? $0 : $1 }
    }
}

public extension Tealium {
    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        encoder.dateEncodingStrategy = .formatted(Date.Formatter.iso8601)
        return encoder
    }()

    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Date.Formatter.iso8601)
        return decoder
    }()

    static let legacyJsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "Infinity", nan: "NaN")
        return decoder
    }()
}
