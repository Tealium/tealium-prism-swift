//
//  DataObject+Extensions.swift
//  Pods
//
//  Created by Enrico Zannini on 19/09/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension DataObject: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: DataItem].self)
        self.init(dictionary: dictionary)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(AnyCodable(asDictionary()))
    }
}

extension DataObject: DataItemExtractor {
    public func getDataItem(key: String) -> DataItem? {
        guard let value = asDictionary()[key] else {
            return nil
        }
        return DataItem(value: value)
    }
}

extension DataObject: DataInputConvertible {
    public func toDataInput() -> any DataInput {
        asDictionary()
    }
}
