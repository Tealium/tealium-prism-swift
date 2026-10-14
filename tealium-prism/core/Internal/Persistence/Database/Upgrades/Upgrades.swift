//
//  Upgrades.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// The registry of every database upgrade step, in version order.
///
/// Steps are stateless types conforming to `DatabaseUpgrade`, one per file under `Upgrades/`,
/// registered as `V1ToV2()`.
///
/// Rules for a step:
/// 1. **A step is frozen once released.** Never edit a shipped step; add the next version instead.
/// 2. **A step doesn't use live constants.** That means no `ModuleSchema`/`ModuleStorageSchema` `Expression`s,
///    no `Modules.Types` and no `VisitorStorage.Keys`. A step carries its own frozen literals, taking table
///    and column names from one `SchemaV<N>` snapshot per version.
/// 3. **A step opens no transaction, and never uses `DataStore`, `Editor` or the repositories.** The whole upgrade
///    is one transaction, so a step has nothing to commit on its own, and a nested `BEGIN` fails; `DataStore`,
///    `Editor` and the repositories each open their own. A step uses raw `Connection` calls only.
/// 4. **Naming:** the step's type name is `V{N-1}ToV{N}`, optionally followed by a suffix that doesn't start with a digit.
/// 5. **A file below `MIN_SUPPORTED_VERSION` is deleted and recreated, not upgraded.**
/// 6. **A step doesn't catch database errors.** If it must rethrow, it throws the original error, not a
///    replacement, so the SQLite error stays visible: MT-2271 will route corruption on it.
///
/// Checklist for adding a step, in this order:
/// 1. **Snapshot the version you upgrade from.** If `SchemaV{N-1}` doesn't exist, add it in `Upgrades/` by copying
///    every table and column name from the live schema (`Internal/Persistence/Schemas/`), which still describes
///    version N-1. Copy the names only, as literal `Table`/`Expression`s, not the query helpers or `createTable`.
///    Add a test that every `SchemaV{N-1}` table and column exists in a database built from `FrozenSchemas.v{N-1}`.
///    If version N-1 didn't change the shape, use a `typealias` to the previous snapshot.
/// 2. **Write the step**, `Upgrades/V{N-1}ToV{N}.swift`, using only `SchemaV{N-1}` names and literals.
/// 3. **If the step changes the shape,** update the live schema and `onCreate`, so a fresh install creates version N.
/// 4. **Bump `DATABASE_VERSION`** and register the step in `Upgrades.all`.
/// 5. **Add `FrozenSchemas.v{N}`** in the test target (`TestHelpers/FrozenSchemas.swift`), captured from what
///    `onCreate` now produces. Never edit an earlier snapshot.
/// 6. **Add an upgrade test**: build a file from `FrozenSchemas.v{N-1}`'s DDL, upgrade it, and compare it with a
///    fresh install structurally (`PRAGMA table_info`, `index_list`, `foreign_key_list` and trigger SQL), not by
///    `sqlite_master` text, because `ALTER` rewrites the stored SQL.
enum Upgrades {
    /// Every upgrade step, sorted by version. Empty until MT-2259 adds V1ToV2.
    static let all: [DatabaseUpgrade] = [DatabaseUpgrade]().sorted { $0.targetVersion < $1.targetVersion }

    /// The steps that take a file from `old` to `new`: above `old`, at or below `new`, in registered order.
    static func since(old: Int, new: Int, upgrades: [DatabaseUpgrade] = all) -> [DatabaseUpgrade] {
        upgrades.filter { $0.targetVersion > old && $0.targetVersion <= new }
    }
}
