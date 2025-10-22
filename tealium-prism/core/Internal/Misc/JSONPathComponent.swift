//
//  JSONPathComponent.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

indirect enum JSONPathComponent: CustomStringConvertible {
    case key(_: String, next: JSONPathComponent?)
    case index(_: Int, next: JSONPathComponent?)

    var description: String {
        switch self {
        case .key(var key, let next):
            if key.containsReservedCharacters() {
                key = "[\"\(key)\"]"
            }
            guard let next else {
                return key
            }
            return "\(key)\(separator(before: next))\(next)"
        case let .index(index, next):
            guard let next else {
                return "[\(index)]"
            }
            return "[\(index)]\(separator(before: next))\(next)"
        }
    }

    private func separator(before next: JSONPathComponent) -> String {
        guard case let .key(component, _) = next else {
            return ""
        }
        return component.containsReservedCharacters() ? "" : "."
    }

    static func + (_ head: JSONPathComponent, component: JSONPathComponent) -> JSONPathComponent {
        switch head {
        case let .key(key, next):
            guard let next else {
                return .key(key, next: component)
            }
            return .key(key, next: next + component)
        case let .index(index, next):
            guard let next else {
                return .index(index, next: component)
            }
            return .index(index, next: next + component)
        }
    }
}

private extension String {
    func containsReservedCharacters() -> Bool {
        JSONPathParsing.matchesInvalidCharacters(in: self) != nil
    }
}
