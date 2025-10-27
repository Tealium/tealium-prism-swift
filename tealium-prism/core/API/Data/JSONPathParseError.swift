//
//  JSONPathParseError.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * An error occurred while trying to parse a `String` into a `JSONPath`
 */
public struct JSONPathParseError: Error, CustomStringConvertible {
    enum Kind: Error {
        case emptyPathComponent
        case invalidFirstComponent
        case invalidArrayIndex(String)
        case unexpectedEndOfInput
        case unclosedQuotedKey
        case invalidCharacter(Character, position: Int)
        case missingSeparator(position: Int)

        var details: String {
            switch self {
            case .emptyPathComponent:
                "Path component cannot be empty"
            case .invalidFirstComponent:
                "First component must be a key for JSON object or an index for JSON array"
            case let .invalidArrayIndex(index):
                "Invalid array index '\(index)' - must be a valid integer"
            case .unclosedQuotedKey:
                "Unclosed quoted key - missing closing bracket and quote"
            case let .invalidCharacter(char, position):
                "Invalid character '\(char)' at position \(position)"
            case let .missingSeparator(position):
                "Missing a separator between components at position \(position)"
            case .unexpectedEndOfInput:
                "Path terminated before completing path component"
            }
        }
    }

    let kind: Kind
    /// The string that was attempted to be parsed.
    public let pathString: String

    init(kind: Kind, pathString: String) {
        self.kind = kind
        self.pathString = pathString
    }

    public var description: String {
        "Failed to parse JSONPath: \(kind.details). Input: '\(pathString)'"
    }
}
