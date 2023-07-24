//
//  TealiumDataValue.swift
//  tealium-swift
//
//  Created by Tyler Rister on 7/13/23.
//

import Foundation

public protocol TealiumDataValue {}
extension Double: TealiumDataValue {}
extension Int: TealiumDataValue {}
extension Bool: TealiumDataValue {}
extension Optional: TealiumDataValue {}
extension String: TealiumDataValue {}
extension [TealiumDataValue]: TealiumDataValue {}

enum TealiumDataValueErrors: Error {
    case dataToStringFailed
    case stringToDataFailed
}

public typealias TealiumDictionary = [String: TealiumDataValue]
public typealias TealiumDictionaryOptionals = [String: TealiumDataValue?]

extension TealiumDictionaryOptionals: TealiumDataValue {}

extension TealiumDataValue {
    func serialize() throws -> String {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "Infinity", nan: "NaN")
        let anyCodable = AnyEncodable(self)
        let jsonData = try jsonEncoder.encode(anyCodable)
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
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "Infinity", nan: "NaN")
        let response = try decoder.decode(AnyCodable.self, from: data)
        return response.value
    }
}
