//
//  DatabaseUpgrade.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

/// One step of the database upgrade chain. Each step is its own stateless type in its own file under
/// `Upgrades/`, named `V{N-1}ToV{N}`, and registered in `Upgrades.all` as an instance, e.g. `V1ToV2()`.
protocol DatabaseUpgrade {
    /// The database version this step upgrades TO.
    var targetVersion: Int { get }
    /// Upgrades the database from `targetVersion - 1` to `targetVersion`. Runs inside the helper's transaction.
    /// A step doesn't catch database errors. If it must rethrow, it throws the original error, not a replacement,
    /// so the SQLite error stays visible: MT-2271 will route corruption on it.
    ///
    /// A step may throw any error: the helper wraps it in a `DatabaseUpgradeError` carrying this step's `targetVersion`,
    /// and the transaction is rolled back.
    func upgrade(_ database: Connection) throws
}
