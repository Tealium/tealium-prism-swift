//
//  FrozenSchemas.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 12/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// The frozen schema of every database version, as the SQL SQLite stored for each schema object.
enum FrozenSchemas {
    // swiftlint:disable line_length identifier_name
    // Android (Kotlin): keeps one regenerated `EXPECTED_SCHEMA`; Swift keeps one frozen snapshot per version (v1 is MT-2259's fixture).
    /// One frozen snapshot per version, never edit an earlier one: add a new version instead.
    /// Keyed by `type|name|tbl_name`, valued by the stored SQL. v1 is the schema created by 0.5.0
    /// and also the source of MT-2259's v1 fixture.
    static let v1: [String: String] = [
        "table|dispatch|dispatch":
            #"CREATE TABLE "dispatch" ("uuid" TEXT PRIMARY KEY NOT NULL, "timestamp" INTEGER NOT NULL, "dispatch" TEXT NOT NULL)"#,
        "table|module|module":
            #"CREATE TABLE "module" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" TEXT NOT NULL UNIQUE)"#,
        "table|module_storage|module_storage":
            #"CREATE TABLE "module_storage" ("module_id" INTEGER NOT NULL, "key" TEXT NOT NULL, "value" TEXT NOT NULL, "expiry" INTEGER NOT NULL, PRIMARY KEY ("module_id", "key"), FOREIGN KEY ("module_id") REFERENCES "module" ("id") ON DELETE CASCADE)"#,
        "table|queue|queue":
            #"CREATE TABLE "queue" ("dispatch_id" TEXT NOT NULL, "processor" TEXT NOT NULL, PRIMARY KEY ("dispatch_id", "processor"), FOREIGN KEY ("dispatch_id") REFERENCES "dispatch" ("uuid") ON DELETE CASCADE)"#,
        "trigger|queue_remove_processed_dispatches|queue": [
            "CREATE TRIGGER queue_remove_processed_dispatches",
            "            AFTER DELETE ON queue",
            "        BEGIN",
            "            DELETE FROM dispatch",
            "            WHERE NOT EXISTS (",
            "                SELECT processor",
            "                  FROM queue",
            "                  WHERE dispatch_id = dispatch.uuid",
            "            );",
            "        END"
        ].joined(separator: "\n")
    ]
    // swiftlint:enable line_length identifier_name

    /// The frozen snapshot of `version`, if there is one.
    static func snapshot(for version: Int) -> [String: String]? {
        [1: v1][version]
    }

    /// The statements that create the frozen schema of `version` on an empty database: tables first, then indexes, then triggers,
    /// each type sorted by key so that the order is deterministic.
    static func createStatements(for version: Int) -> [String]? {
        guard let snapshot = snapshot(for: version) else {
            return nil
        }
        return ["table", "index", "trigger"].flatMap { type in
            snapshot.keys
                .filter { $0.hasPrefix("\(type)|") }
                .sorted()
                .compactMap { snapshot[$0] }
                .filter { !$0.isEmpty }
        }
    }
}
