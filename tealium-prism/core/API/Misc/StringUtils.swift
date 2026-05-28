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
}
