//
//  JSONPath+Extensions.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension JSONPath {

    /// Renders the path as a `String`
    public func render() -> String {
        render(components: components)
    }

    private func render(components: [JSONPathComponent<Root>]) -> String {
        guard !components.isEmpty else {
            return ""
        }
        var components = components
        let current = components.removeFirst().render()
        let next = components.first
        guard let next else {
            return current
        }
        return current + separator(before: next) + render(components: components)
    }

    private func separator(before next: JSONPathComponent<Root>) -> String {
        next.rendersWithBracketsNotation() ? "" : "."
    }
}

extension JSONPath: Equatable {
    public static func == (lhs: JSONPath, rhs: JSONPath) -> Bool {
        lhs.render() == rhs.render()
    }
}
