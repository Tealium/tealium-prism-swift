//
//  Comparable+Coerce.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 13/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension Comparable {
    /// Coerce self to be between the provided min and max.
    func coerce(min: Self, max: Self) -> Self {
        if self < min {
            return min
        }
        if self > max {
            return max
        }
        return self
    }
}
