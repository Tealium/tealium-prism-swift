//
//  StringContainer+Converter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 31/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension StringContainer {
    struct Converter: DataItemConverter {
        typealias Convertible = StringContainer
        func convert(dataItem: DataItem) -> Convertible? {
            guard let object = dataItem.getDataDictionary(),
                  let value = object.get(key: Keys.value, as: String.self) else {
                return nil
            }
            return StringContainer(value)
        }
    }

    static let converter = Converter()
}
