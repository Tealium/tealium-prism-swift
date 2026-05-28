//
//  ReferenceContainer+Converter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 30/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension ReferenceContainer {
    struct Converter: DataItemConverter {
        typealias Convertible = ReferenceContainer
        func convert(dataItem: DataItem) -> Convertible? {
            guard let object = dataItem.getDataDictionary() else {
                return nil
            }
            if let pathString = object.get(key: Keys.path, as: String.self),
                      let path = try? JSONObjectPath.parse(pathString) {
                return .path(path)
            } else if let key = object.get(key: Keys.key, as: String.self) {
                return .key(key)
            }
            return nil
        }
    }

    public static let converter: any DataItemConverter<ReferenceContainer> = Converter()
}
