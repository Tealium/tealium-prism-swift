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
            key.isAllowedPathKey ? key : escape(key)
        case let .index(index):
            "[\(index)]"
        }
    }

    private func escape(_ key: String) -> String {
        // Prefer double quote if not contained for clarity
        let quote = (!key.contains("\"") || key.contains("'")) ? "\"" : "'"
        let escaped = key.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\(quote)", with: "\\\(quote)")
        return "[\(quote)\(escaped)\(quote)]"
    }

    func rendersWithBracketsNotation() -> Bool {
        guard case let .key(component) = self else {
            return true
        }
        return !component.isAllowedPathKey
    }
}

private extension String {
    /// Returns true if it is allowed as a path key, or false if it needs to be rendered with brackets notation.
    var isAllowedPathKey: Bool {
        guard let first, // invalid empty component
              first.isAllowedPathKeyStart else { // invalid number first component
            return false
        }
        return allSatisfy { $0.isAllowedPathKeyBody }
    }
}
