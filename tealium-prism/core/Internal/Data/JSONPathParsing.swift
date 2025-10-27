//
//  JSONPathParsing.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

private let basicKeyRegex = try? NSRegularExpression(pattern: "[^a-zA-Z0-9_]")

/**
 * A non copyable, consuming on start, struct that represents the process of parsing a specific `pathString`.
 */
struct JSONPathParsing<Root: PathRoot>: ~Copyable {
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
        var components = [try parseNextComponent(first: true)]
        while cursor < pathString.endIndex {
            components.append(try parseNextComponent())
        }
        return components
    }

    /// Parse entire next component: .property or ["property"] or [123]
    private mutating func parseNextComponent(first: Bool = false) throws(JSONPathParseError.Kind) -> JSONPathComponent<Root> {
        switch try getCharAtCursor() {
        case "[":
            return try parseSquareBracketsComponent()
        case "." where !first: // Handle dot separator for all components except the first
            // Skip dot
            shiftCursor()
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
        shiftCursor()
        if try getCharAtCursor() == "\"" {
            // Skip opening quote
            shiftCursor()
            // Parse quoted key without opening: key\"]
            return try .key(parseNextQuotedKey())
        } else {
            // Parse array index without opening: 123]
            return try .index(parseNextArrayIndex())
        }
    }

    /// Parse direct key: some_property123
    private mutating func parseNextKey() throws(JSONPathParseError.Kind) -> String {
        var key = ""
        let startIndex = cursor

        while cursor < pathString.endIndex {
            let char = try getCharAtCursor()
            guard char != "." && char != "[" else {
                break
            }
            key.append(char)
            // Go to next character
            shiftCursor()
        }

        guard !key.isEmpty else {
            throw .emptyPathComponent
        }

        // Validate entire key contains only alphanumeric characters and underscores
        if let match = Self.matchesSpecialCharacters(in: key) {
            let invalidCharIndex = match.range.location
            let invalidChar = key[key.index(key.startIndex, offsetBy: invalidCharIndex)]
            let position = position(of: startIndex) + invalidCharIndex
            throw .invalidCharacter(invalidChar, position: position)
        }

        return key
    }

    static func matchesSpecialCharacters(in key: String) -> NSTextCheckingResult? {
        guard let regex = basicKeyRegex else {
            return nil
        }
        return regex.firstMatch(in: key,
                                range: NSRange(location: 0, length: key.count))
    }

    /// Parse quoted key without openings: property"]
    private mutating func parseNextQuotedKey() throws(JSONPathParseError.Kind) -> String {
        var key = ""

        while try getCharAtCursor() != "\"" {
            key.append(try getCharAtCursor())
            // Go to next character
            shiftCursor()
        }

        // Skip closing quote
        shiftCursor()

        guard try getCharAtCursor() == "]" else {
            throw .unclosedQuotedKey
        }

        // Skip closing bracket
        shiftCursor()

        guard !key.isEmpty else {
            throw .emptyPathComponent
        }

        return key
    }

    /// Parse array index without openings: 123]
    private mutating func parseNextArrayIndex() throws(JSONPathParseError.Kind) -> Int {
        var indexString = ""

        while try getCharAtCursor() != "]" {
            indexString.append(try getCharAtCursor())
            shiftCursor()
        }

        // Skip closing bracket
        shiftCursor()

        guard !indexString.isEmpty else {
            throw .emptyPathComponent
        }

        guard let arrayIndex = Int(indexString), arrayIndex >= 0 else {
            throw .invalidArrayIndex(indexString)
        }

        return arrayIndex
    }

    private func getCharAtCursor() throws(JSONPathParseError.Kind) -> Character {
        guard cursor < pathString.endIndex else {
            throw .unexpectedEndOfInput
        }
        return pathString[cursor]
    }

    private mutating func shiftCursor() {
        cursor = pathString.index(after: cursor)
    }

    private func position(of index: String.Index) -> Int {
        pathString.distance(from: pathString.startIndex, to: index)
    }
}
