//
//  TealiumDataInput.swift
//  tealium-swift
//
//  Created by Tyler Rister on 13/7/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * `TealiumDataInput` is a protocol that we use internally to limit the type of data that can be sent to Tealium to later serialize it into JSON.
 *
 * - Warning: Do not conform custom types to the `TealiumDataInput` protocol or it will defeat the purpose of this protocol.
 */
public protocol TealiumDataInput {}
extension Double: TealiumDataInput {}
extension Float: TealiumDataInput {}
extension Int: TealiumDataInput {}
extension Int64: TealiumDataInput {}
extension Int32: TealiumDataInput {}
extension Int16: TealiumDataInput {}
extension Int8: TealiumDataInput {}
extension Bool: TealiumDataInput {}
extension String: TealiumDataInput {}
extension NSNumber: TealiumDataInput {}
extension Array: TealiumDataInput where Element == TealiumDataInput {}
extension Dictionary: TealiumDataInput where Key == String, Value == TealiumDataInput { }
public protocol TealiumDataInputConvertible {
    func toDataInput() -> TealiumDataInput
}
extension Array: TealiumDataInputConvertible where Element: TealiumDataInput {
    public func toDataInput() -> TealiumDataInput {
        self as [TealiumDataInput]
    }
}
extension Dictionary: TealiumDataInputConvertible where Key == String, Value: TealiumDataInput {
    public func toDataInput() -> TealiumDataInput {
        self as [String: TealiumDataInput]
    }
}
enum TealiumDataValueErrors: Error {
    case dataToStringFailed
    case stringToDataFailed
}

extension TealiumDataInput {
    func serialize() throws -> String {
        return try AnyEncodable(self).serialize()
    }
}

extension AnyEncodable {
    func serialize() throws -> String {
        let jsonEncoder = Tealium.jsonEncoder
        let jsonData = try jsonEncoder.encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw TealiumDataValueErrors.dataToStringFailed
        }
        return jsonString
    }
}

extension String {
    func deserialize() throws -> Any {
        guard let data = self.data(using: .utf8) else {
            throw TealiumDataValueErrors.stringToDataFailed
        }
        let decoder = Tealium.jsonDecoder
        let response = try decoder.decode(AnyCodable.self, from: data)
        return response.value
    }
}
