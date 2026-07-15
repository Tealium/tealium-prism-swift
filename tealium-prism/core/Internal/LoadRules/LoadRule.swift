//
//  LoadRule.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 25/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct LoadRule: Equatable {
    let id: String
    let conditions: Rule<Condition>
}

extension LoadRule {
    enum Keys {
        static let id = "id"
        static let conditions = "conditions"
    }
    struct Converter: DataItemConverter {
        typealias Convertible = LoadRule
        let ruleConverter = Rule.converter(ruleItemConverter: Condition.converter)
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let id: String = dictionary.get(key: Keys.id),
                  let conditions = dictionary.getDataItem(key: Keys.conditions),
                  let rules = conditions.getConvertible(converter: ruleConverter)
            else {
                return nil
            }
            return LoadRule(id: id, conditions: rules)
        }
    }
    static let converter: any DataItemConverter<LoadRule> = Converter()
}
