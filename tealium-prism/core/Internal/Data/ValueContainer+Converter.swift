//
//  ValueContainer+Converter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 31/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension ValueContainer {
    struct Converter: DataItemConverter {
        typealias Convertible = ValueContainer
        func convert(dataItem: DataItem) -> Convertible? {
            guard let object = dataItem.getDataDictionary(),
                  let value = object.get(key: Keys.value, as: String.self) else {
                return nil
            }
            return ValueContainer(value)
        }
    }

    static let converter = Converter()
}
