//
//  JSONPathComponent.swift
//  Pods
//
//  Created by Enrico Zannini on 22/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A component for a JSONPath.
 * `Root` is a Phantom Type that refers to the root JSON (object or array) onto which the path can be applied to.
 */
enum JSONPathComponent<Root: PathRoot> {
    case key(String)
    case index(Int)

    func render() -> String {
        switch self {
        case let .key(key):
            if key.containsSpecialCharacters() {
                "[\"\(key)\"]"
            } else {
                key
            }
        case let .index(index):
            "[\(index)]"
        }
    }

    func rendersWithBracketsNotation() -> Bool {
        guard case let .key(component) = self else {
            return true
        }
        return component.containsSpecialCharacters()
    }
}

private extension String {
    func containsSpecialCharacters() -> Bool {
        JSONPathParsing<ObjectRoot>.matchesSpecialCharacters(in: self) != nil
    }
}
