//
//  Rule+DataInputConvertible.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension Rule: DataInputConvertible where Item: DataInputConvertible {
    public func toDataInput() -> any DataInput {
        switch self {
        case .and(let children):
            [
                RuleKeys.operator: BooleanOperators.and,
                RuleKeys.children: children.toDataInput()
            ]
        case .or(let children):
            [
                RuleKeys.operator: BooleanOperators.or,
                RuleKeys.children: children.toDataInput()
            ]
        case .not(let child):
            [
                RuleKeys.operator: BooleanOperators.not,
                RuleKeys.children: [child.toDataInput()]
            ]
        case .just(let item):
            item.toDataInput()
        }
    }
}
