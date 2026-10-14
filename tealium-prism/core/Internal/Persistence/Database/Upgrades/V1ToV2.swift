//
//  V1ToV2.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

/// Upgrades the database from version 1 to 2, moving the visitor data that 0.4.0 to 0.6.0 kept in the `shared` store
/// to the `VisitorId` store, which `VisitorStorage` reads. Only the owning module and the key change:
///
/// | In `shared` (version 1)                   | In `VisitorId` (version 2) |
/// | ----------------------------------------- | -------------------------- |
/// | `visitorId`                               | `visitor_id`               |
/// | `currentIdentity`                         | `owner_identity`           |
/// | `<sha256>` (64 lower-case hex characters) | `identity.<sha256>`        |
///
/// `value` and `expiry` are never touched, so they stay byte for byte what was stored.
///
/// 0.1.0 to 0.3.0 kept the visitor data in a `visitor` module, which 0.4.0 abandoned without moving it. This step doesn't
/// read that module: it is out of scope.
///
/// - Rows are selected by inclusion: the shared store is reachable from public API through
///   `ModuleStoreProvider.getModuleStore(name:)`, so anything not positively recognised as visitor data stays where it is.
/// - The guard (is there a `visitorId` to move?) is a separate query rather than an `EXISTS` in the `UPDATE`, so correctness
///   doesn't depend on how SQLite evaluates an uncorrelated subquery. It also keeps rows that merely look like
///   associations from being claimed when no visitor id was ever written.
/// - It is idempotent: a second run matches nothing. With no shared store or no visitor id nothing moves, and the
///   `VisitorId` module row isn't created.
///
/// The SQL relies on three assumptions; the first two are pinned by `Sha256Tests` and `DataInputTests`, the third is an accepted risk:
/// - `String.sha256()` is lower-case hex, and `GLOB` is case sensitive.
/// - String values are stored JSON-quoted (`"abc"` with its quotes).
/// - No other writer of the shared store uses 64-character lower-case hex keys. Any module can write there.
///
/// It follows the rules in `Upgrades`.
/// Its literals are frozen copies of the names on disk, deliberately not the live constants.
///
/// It uses plain `String` names rather than SQLite.swift `Expression`s or query builders: rows are moved and renamed
/// inside SQL, and no stored value is read into Swift, so typed columns would add nothing.
struct V1ToV2: DatabaseUpgrade {

    let targetVersion = 2

    static let sourceModuleName = "shared"
    static let targetModuleName = "VisitorId"

    static let sourceKeyVisitorId = "visitorId"
    static let sourceKeyOwnerIdentity = "currentIdentity"

    static let targetKeyVisitorId = "visitor_id"
    static let targetKeyOwnerIdentity = "owner_identity"
    static let targetPrefixIdentity = "identity."

    func upgrade(_ database: Connection) throws {
        // A missing count is an error, not zero: zero would stamp version 2 and skip the move for good.
        guard let visitorIdRows = try database.scalar(Self.countSourceVisitorId) as? Int64 else {
            throw MissingCountError()
        }
        guard visitorIdRows > 0 else { return }

        try database.execute(Self.insertTargetModule)
        try database.execute(Self.moveVisitorRows)
    }

    struct MissingCountError: Error { }

    private typealias Module = SchemaV1.Module
    private typealias Storage = SchemaV1.ModuleStorage

    private static func moduleId(named name: String) -> String {
        "(SELECT \(Module.id) FROM \(Module.table) WHERE \(Module.name) = '\(name)')"
    }

    // Android (Kotlin): V3ToV4 lower-cases its upper-case v3 digests, so its GLOB differs; here the digests are already lower-case.
    /// The one definition of "this row belongs to the visitor id store". GLOB is case sensitive.
    private static let isVisitorRow = """
        \(Storage.key) IN ('\(sourceKeyVisitorId)', '\(sourceKeyOwnerIdentity)')
            OR (
                length(\(Storage.key)) = 64
                    AND \(Storage.key) NOT GLOB '*[^0-9a-f]*'
                    AND \(Storage.value) GLOB '"*"'
            )
        """

    /// The guard: zero means there is nothing to move.
    static let countSourceVisitorId = """
        SELECT COUNT(*) FROM \(Storage.table)
        WHERE \(Storage.moduleId) = \(moduleId(named: sourceModuleName))
            AND \(Storage.key) = '\(sourceKeyVisitorId)';
        """

    /// Creates the target module row. `module.name` is UNIQUE, and the row may already exist.
    static let insertTargetModule = """
        INSERT OR IGNORE INTO \(Module.table) (\(Module.name))
        VALUES ('\(targetModuleName)');
        """

    /// Re-points every visitor row at the target store and renames its key; value and expiry untouched.
    static let moveVisitorRows = """
        UPDATE OR REPLACE \(Storage.table)
        SET \(Storage.moduleId) = \(moduleId(named: targetModuleName)),
            \(Storage.key) = CASE \(Storage.key)
                WHEN '\(sourceKeyVisitorId)' THEN '\(targetKeyVisitorId)'
                WHEN '\(sourceKeyOwnerIdentity)' THEN '\(targetKeyOwnerIdentity)'
                ELSE '\(targetPrefixIdentity)' || \(Storage.key) END
        WHERE \(Storage.moduleId) = \(moduleId(named: sourceModuleName))
            AND (\(isVisitorRow));
        """
}
