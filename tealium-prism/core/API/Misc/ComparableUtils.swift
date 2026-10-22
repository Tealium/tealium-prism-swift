//
//  ComparableUtils.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 03/04/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

/// Namespace for utils method for Comparable objects.
public enum ComparableUtils {
    /// Coerce value to be between the provided min and max.
    public static func coerce<T: Comparable>(_ value: T, min: T, max: T) -> T {
        value.coerce(min: min, max: max)
    }
}
