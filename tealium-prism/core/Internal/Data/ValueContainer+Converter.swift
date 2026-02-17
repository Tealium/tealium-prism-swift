//
//  ValueContainer+Converter.swift
//  tealium-prism
//
//  Created by Den Guzov on 28/01/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

extension ValueContainer {
    struct Converter: DataItemConverter {
        typealias Convertible = ValueContainer
        func convert(dataItem: DataItem) -> Convertible? {
            guard let object = dataItem.getDataDictionary(),
                  let value = object.getDataItem(key: Keys.value) else {
                return nil
            }
            return ValueContainer(item: value)
        }
    }

    static let converter = Converter()
}
