//
//  Serialize.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 19/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension DataInput {
    func serialize() throws -> String {
        return try AnyEncodable(self).serialize()
    }
}

extension DataObject {
    func serialize() throws -> String {
        try asDictionary().serialize()
    }
}

extension AnyEncodable {
    func serialize() throws -> String {
        let jsonEncoder = Tealium.jsonEncoder
        let jsonData = try jsonEncoder.encode(self)
        // swiftlint:disable:next optional_data_string_conversion
        return String(decoding: jsonData, as: UTF8.self) // Safe as we just used encode that returns UTF8 formatted data
    }
}
