//
//  Rule+Matchable.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension Rule<Matchable>: Matchable {
    public func matches(payload: DataObject) -> Bool {
        switch self {
        case .and(let children):
            children.allSatisfy { $0.matches(payload: payload) }
        case .or(let children):
            children.contains { $0.matches(payload: payload) }
        case .not(let child):
            !child.matches(payload: payload)
        case .just(let item):
            item.matches(payload: payload)
        }
    }
}

extension Rule where Item: Matchable {
    func asMatchable() -> Rule<Matchable> {
        asMatchable(converter: { .just($0) })
    }
}

extension Rule {
    func asMatchable(converter: (Item) -> Rule<Matchable>) -> Rule<Matchable> {
        switch self {
        case .and(let rules):
            return .and(rules.map { $0.asMatchable(converter: converter) })
        case .or(let rules):
            return .or(rules.map { $0.asMatchable(converter: converter) })
        case .not(let applier):
            return .not(applier.asMatchable(converter: converter))
        case .just(let item):
            return converter(item)
        }
    }
}
