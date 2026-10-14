//
//  DatabaseUpgradeError.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A database upgrade failed. Internal: the provider turns it into in-memory storage, so apps never see it.
struct DatabaseUpgradeError: Error {
    /// The version the failed step was upgrading to, or the first expected version not registered exactly once (`new` when only the order is wrong).
    let targetVersion: Int
    /// What the step threw, or a `BrokenChain`.
    let underlying: Error

    /// The steps registered for `old + 1 ... new` aren't exactly one per version, in order.
    struct BrokenChain: Error, CustomStringConvertible {
        let old: Int
        let new: Int
        let expected: [Int]
        let registered: [Int]

        var description: String {
            "Upgrade chain from \(old) to \(new) is not contiguous: expected \(expected), registered \(registered)"
        }
    }
}
