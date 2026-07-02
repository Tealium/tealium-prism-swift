//
//  StringUtils.swift
//  tealium-prism
//
//  Created by Den Guzov on 16/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A collection of utility functions for working with strings.
public enum StringUtils {
    /// Returns `true` if the string is empty or contains only whitespace characters.
    public static func isBlank(_ string: String) -> Bool {
        string.isBlank // internal extension method
    }

    /// Generates a lowercase UUID string for cross-platform consistency.
    ///
    /// Java's `UUID.toString()` returns lowercase by default, so this method ensures
    /// the Swift SDK generates consistent UUID formats across platforms.
    ///
    /// - Returns: A lowercase UUID string (e.g., "e621e1f8-c36c-495a-93fc-0c247a3e6e5f").
    public static func generateUUID() -> String {
        UUID().uuidString.lowercased()
    }
}
