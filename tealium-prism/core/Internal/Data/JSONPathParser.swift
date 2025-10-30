//
//  JSONPathParser.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A non copyable, consuming on start, struct that parses a specific `pathString`.
 */
struct JSONPathParser<Root: PathRoot>: ~Copyable {
    let pathString: String
    private var cursor: String.Index

    init(pathString: String) {
        self.pathString = pathString
        self.cursor = pathString.startIndex
    }

    /**
     * Starts the parsing process and returns a `JSONPath` if successful.
     * Consumes this object upon being called so this method can't be called again.
     */
    consuming func start() throws(JSONPathParseError.Kind) -> [JSONPathComponent<Root>] {
        var components = [JSONPathComponent<Root>]()
        repeat {
            components.append(try parseNextComponent(first: components.isEmpty))
        } while hasNext()
        return components
    }

    /// Parse entire next component: .property or ["property"] or [123]
    private mutating func parseNextComponent(first: Bool) throws(JSONPathParseError.Kind) -> JSONPathComponent<Root> {
        switch try peek() {
        case "[":
            return try parseSquareBracketsComponent()
        case "." where !first: // Handle dot separator for all components except the first
            // Skip dot
            try shift()
            // Parse regular key
            return try .key(parseNextKey())
        default:
            guard first else {
                throw .missingSeparator(position: position(of: cursor))
            }
            return try .key(parseNextKey())
        }
    }

    // Parse quoted key [\"key\"] or array index [123]
    private mutating func parseSquareBracketsComponent() throws(JSONPathParseError.Kind) -> JSONPathComponent<Root> {
        // Skip opening bracket
        try shift()
        switch try peek() {
        case "\"", "'":
            // Parse quoted key without opening bracket: \"key\"] or 'key']
            return try .key(parseNextQuotedKey())
        default:
            // Parse array index without opening bracket: 123]
            return try .index(parseNextArrayIndex())
        }
    }

    /// Parse direct key: some_property123
    private mutating func parseNextKey() throws(JSONPathParseError.Kind) -> String {
        let firstChar = try next()
        guard firstChar.isAllowedPathKeyStart else {
            throw .invalidCharacter(firstChar,
                                    position: position(of: cursor) - 1,
                                    expected: "Key starting with a letter or underscore")
        }
        var key = "\(firstChar)"
        while hasNext() {
            let char = try peek()
            guard char != "." && char != "[" else {
                break
            }
            guard char.isAllowedPathKeyBody else {
                throw .invalidCharacter(char,
                                        position: position(of: cursor),
                                        expected: "Alphanumeric characters or underscores inside a key")
            }
            key.append(char)
            // Go to next character
            try shift()
        }

        return key
    }

    /// Parse quoted key without opening bracket: "property"] or 'property']  `container["\"property\"]`
    private mutating func parseNextQuotedKey() throws(JSONPathParseError.Kind) -> String {
        var key = ""
        let quote = try next()
        var escaping = false
        var quoteFound = false
        while !quoteFound {
            let char = try next()
            if escaping {
                switch char {
                // Only escapable characters
                case "\"", "'", "\\":
                    key.append(char)
                    escaping = false
                default:
                    throw .invalidCharacter(char,
                                            position: position(of: cursor) - 1,
                                            expected: "One of the escapable characters: single quote ('), double quote (\") or another backslash (\\)")
                }
            } else {
                switch char {
                case quote:
                    // Unescaped quote, ended quoted key
                    quoteFound = true
                case "\\":
                    // Escape next char, don't add the escape
                    escaping = true
                default:
                    key.append(char)
                }
            }
        }

        // Skip closing bracket
        try expect("]")

        return key
    }

    /// Parse array index without openings: 123]
    private mutating func parseNextArrayIndex() throws(JSONPathParseError.Kind) -> Int {
        var indexString = ""

        while true {
            let char = try next()
            guard char != "]" else {
                break
            }
            indexString.append(char)
        }

        guard !indexString.isEmpty else {
            throw .invalidCharacter("]",
                                    position: position(of: cursor) - 1,
                                    expected: "Integer index in square brackets")
        }

        guard let arrayIndex = Int(indexString), arrayIndex >= 0 else {
            throw .invalidArrayIndex(indexString)
        }

        return arrayIndex
    }

    private mutating func expect(_ char: Character) throws(JSONPathParseError.Kind) {
        let new = try next()
        guard new == char else {
            throw .invalidCharacter(new,
                                    position: position(of: cursor) - 1,
                                    expected: "\(char)")
        }
    }

    /// Returns true if there are still more characters left to consume.
    private func hasNext() -> Bool {
        cursor < pathString.endIndex
    }

    /// Consumes and returns the current character.
    private mutating func next() throws(JSONPathParseError.Kind) -> Character {
        let char = try peek()
        try shift()
        return char
    }

    private func peek() throws(JSONPathParseError.Kind) -> Character {
        guard hasNext() else {
            throw .unexpectedEndOfInput
        }
        return pathString[cursor]
    }

    private mutating func shift() throws(JSONPathParseError.Kind) {
        guard hasNext() else {
            throw .unexpectedEndOfInput
        }
        cursor = pathString.index(after: cursor)
    }

    private func position(of index: String.Index) -> Int {
        pathString.distance(from: pathString.startIndex, to: index)
    }
}
