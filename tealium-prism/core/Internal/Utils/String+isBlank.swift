//
//  String+isBlank.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/01/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

extension String {
    /// Returns true if it's empty or if it only contains whitespaces.
    var isBlank: Bool {
        allSatisfy { $0.isWhitespace }
    }
}
