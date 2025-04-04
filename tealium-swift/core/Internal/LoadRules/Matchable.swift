//
//  Matchable.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol to verify if an object matches a payload. To be used with the `Condition` engine.
protocol Matchable {
    /// - returns: true if the object matches the given payload.
    func matches(payload: DataObject) -> Bool
}
