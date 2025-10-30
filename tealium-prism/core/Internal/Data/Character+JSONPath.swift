//
//  Character+JSONPath.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 29/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

extension Character {
    var isAllowedPathKeyStart: Bool {
        isLetter || self == "_"
    }

    var isAllowedPathKeyBody: Bool {
        isLetter || isNumber || self == "_"
    }
}
