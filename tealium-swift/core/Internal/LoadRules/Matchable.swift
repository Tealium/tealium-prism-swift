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
    /// - throws: error conforming to `InvalidMatchError` if the matching operation cannot be done.
    func matches(payload: DataObject) throws -> Bool
}
