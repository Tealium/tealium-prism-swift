//
//  OptionalInt+Comparison.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 17/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

extension Optional where Wrapped == Int {
    static func > (lhs: Int?, rhs: Int) -> Bool {
        if let value = lhs {
            return value > rhs
        }
        return false
    }
}
