//
//  Condition+Converter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension Condition {
    enum Keys {
        static let path = "path"
        static let variable = "variable"
        static let `operator` = "operator"
        static let filter = "filter"
    }
    struct Converter: DataItemConverter {
        typealias Convertible = Condition
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let operatorString: String = dictionary.get(key: Keys.operator),
                  let operatorValue = Condition.Operator(rawValue: operatorString),
                  let variable: String = dictionary.get(key: Keys.variable)
            else {
                return nil
            }
            return Condition(path: dictionary.getArray(key: Keys.path)?.compactMap { $0 },
                             variable: variable,
                             operator: operatorValue,
                             filter: dictionary.get(key: Keys.filter))
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
