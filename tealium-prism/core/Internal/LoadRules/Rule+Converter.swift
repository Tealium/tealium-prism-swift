//
//  Rule+Converter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

enum RuleKeys {
    static let children = "children"
    static let `operator` = "operator"
}
enum BooleanOperators {
    static let and = "and"
    static let or = "or"
    static let not = "not"
}

extension Rule {
    typealias Keys = RuleKeys

    struct Converter: DataItemConverter {
        let ruleItemConverter: any DataItemConverter<Item>
        init(ruleItemConverter: any DataItemConverter<Item>) {
            self.ruleItemConverter = ruleItemConverter
        }
        typealias Convertible = Rule
        func convert(dataItem: DataItem) -> Convertible? {
            if let converted = dataItem.getConvertible(converter: ruleItemConverter) {
                return .just(converted)
            }
            let dictionary = dataItem.getDataDictionary()
            guard let children = dictionary?.getDataArray(key: Keys.children),
                  let operatorString: String = dictionary?.get(key: Keys.operator)
            else {
                return nil
            }
            let mappedChildren = children.compactMap { childrenItem in
                return self.convert(dataItem: childrenItem)
            }
            guard !mappedChildren.isEmpty else {
                return nil
            }
            switch operatorString.lowercased() {
            case BooleanOperators.and:
                return .and(mappedChildren)
            case BooleanOperators.or:
                return .or(mappedChildren)
            case BooleanOperators.not:
                return .not(mappedChildren[0])
            default:
                return nil
            }
        }
    }
    static func converter(ruleItemConverter: any DataItemConverter<Item>) -> any DataItemConverter<Self> {
        Converter(ruleItemConverter: ruleItemConverter)
    }
}
