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
                  let referenceContainer = dictionary.getConvertible(key: Keys.variable, converter: ReferenceContainer.converter)
            else {
                return nil
            }
            return Condition(variable: referenceContainer,
                             operator: operatorValue,
                             filter: dictionary.getConvertible(key: Keys.filter, converter: StringContainer.converter))
        }
    }
    static let converter: any DataItemConverter<Condition> = Converter()
}
