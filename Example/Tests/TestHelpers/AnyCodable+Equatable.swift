//
//  AnyCodable+Equatable.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumSwift

extension AnyCodable: @retroactive Equatable, EqualValues {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        return areEquals(lhs: lhs.value, rhs: rhs.value)
    }
}

extension AnyEncodable: @retroactive Equatable, EqualValues {
    public static func == (lhs: AnyEncodable, rhs: AnyEncodable) -> Bool {
        return areEquals(lhs: lhs.value, rhs: rhs.value)
    }
}

extension AnyDecodable: @retroactive Equatable, EqualValues {
    public static func == (lhs: AnyDecodable, rhs: AnyDecodable) -> Bool {
        return areEquals(lhs: lhs.value, rhs: rhs.value)
    }
}

protocol EqualValues {
}

extension EqualValues {
    static func areEquals(lhs: Any, rhs: Any) -> Bool {
        switch (lhs, rhs) {
        case is (Void, Void),
             is (Void, NSNull),
             is (NSNull, NSNull),
             is (NSNull, Void):
            return true
        case let (lhs as Bool, rhs as Bool): return lhs == rhs
        case let (lhs as Int, rhs as Int): return lhs == rhs
        case let (lhs as Int8, rhs as Int8): return lhs == rhs
        case let (lhs as Int16, rhs as Int16): return lhs == rhs
        case let (lhs as Int32, rhs as Int32): return lhs == rhs
        case let (lhs as Int64, rhs as Int64): return lhs == rhs
        case let (lhs as UInt, rhs as UInt): return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8): return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16): return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32): return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64): return lhs == rhs
        case let (lhs as Float, rhs as Float): return lhs == rhs
        case let (lhs as Double, rhs as Double): return lhs == rhs
        case let (lhs as String, rhs as String): return lhs == rhs
        case let (lhs as Date, rhs as Date): return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return lhs == rhs
        case let (lhs as [String: AnyEncodable], rhs as [String: AnyEncodable]):
            return lhs == rhs
        case let (lhs as [String: AnyDecodable], rhs as [String: AnyDecodable]):
            return lhs == rhs
        case let (lhs as [AnyCodable], rhs as [AnyCodable]): return lhs == rhs
        case let (lhs as [AnyEncodable], rhs as [AnyEncodable]): return lhs == rhs
        case let (lhs as [AnyDecodable], rhs as [AnyDecodable]): return lhs == rhs
        default: return false
        }
    }

}
