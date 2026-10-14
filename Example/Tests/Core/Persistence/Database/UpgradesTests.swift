//
//  UpgradesTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 09/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

final class UpgradesTests: XCTestCase {

    private func upgrade(_ version: Int) -> DatabaseUpgrade {
        TestUpgrade(targetVersion: version)
    }

    private func name(of step: DatabaseUpgrade) -> String {
        String(describing: type(of: step))
    }

    /// `V{version-1}ToV{version}`, optionally followed by a suffix that doesn't start with a digit.
    private func isValidName(_ name: String, forVersion version: Int) -> Bool {
        let prefix = "V\(version - 1)ToV\(version)"
        guard name.hasPrefix(prefix) else { return false }
        guard let next = name.dropFirst(prefix.count).first else { return true }
        return !next.isNumber
    }

    // MARK: - since

    func test_since_includes_only_steps_above_old_and_up_to_new() {
        let upgrades = [upgrade(2), upgrade(3), upgrade(4), upgrade(5)]
        let versions = Upgrades.since(old: 2, new: 4, upgrades: upgrades).map { $0.targetVersion }
        XCTAssertEqual(versions, [3, 4])
    }

    func test_since_keeps_the_registered_order() {
        let upgrades = [upgrade(4), upgrade(2), upgrade(3)]
        let versions = Upgrades.since(old: 1, new: 4, upgrades: upgrades).map { $0.targetVersion }
        XCTAssertEqual(versions, [4, 2, 3])
    }

    func test_since_is_empty_when_old_equals_new() {
        XCTAssertTrue(Upgrades.since(old: 3, new: 3, upgrades: [upgrade(2), upgrade(3), upgrade(4)]).isEmpty)
    }

    // MARK: - Registry

    func test_all_versions_cover_every_version_after_the_min_supported_up_to_the_current_one() {
        let versions = Upgrades.all.map { $0.targetVersion }
        // `Upgrades.all` sorts itself (as Kotlin's does), so this holds today; it's checked separately so a change to how the registry is built fails here with a direct message.
        XCTAssertEqual(versions, versions.sorted())
        XCTAssertEqual(Set(versions).count, versions.count, "Versions must not repeat")
        let firstVersion = DatabaseHelper.MIN_SUPPORTED_VERSION
        let expected = DatabaseHelper.DATABASE_VERSION > firstVersion
            ? Array(firstVersion + 1 ... DatabaseHelper.DATABASE_VERSION)
            : []
        XCTAssertEqual(versions, expected)
    }

    func test_all_names_follow_the_naming_convention() {
        for upgrade in Upgrades.all {
            let stepName = name(of: upgrade)
            XCTAssertTrue(isValidName(stepName, forVersion: upgrade.targetVersion),
                          "\(stepName) must be named V\(upgrade.targetVersion - 1)ToV\(upgrade.targetVersion), optionally followed by a non-digit suffix")
        }
    }

    func test_naming_check_accepts_and_rejects_the_expected_names() {
        struct V1ToV2Sample: DatabaseUpgrade {
            let targetVersion = 2
            func upgrade(_ database: Connection) throws {}
        }
        XCTAssertEqual(name(of: V1ToV2Sample()), "V1ToV2Sample")
        XCTAssertTrue(isValidName("V1ToV2", forVersion: 2))
        XCTAssertTrue(isValidName("V1ToV2Visitor", forVersion: 2))
        XCTAssertFalse(isValidName("V1ToV3", forVersion: 2))
        XCTAssertFalse(isValidName("V2ToV3", forVersion: 2))
        XCTAssertFalse(isValidName("V1ToV22", forVersion: 2))
    }

    // MARK: - Frozen schema

    /// The schema objects of `connection` keyed by `type|name|tbl_name`, valued by the stored SQL.
    /// sqlite_sequence and sqlite_autoindex_* are created by SQLite from the DDL (their sql is NULL), and the pinned DDL already carries every UNIQUE and PRIMARY KEY.
    private func schemaObjects(of connection: Connection) throws -> [String: String] {
        var objects = [String: String]()
        for row in try connection.prepare("SELECT type, name, tbl_name, sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'") {
            let key = "\(row[0] ?? "")|\(row[1] ?? "")|\(row[2] ?? "")"
            objects[key] = row[3] as? String ?? ""
        }
        return objects
    }

    func test_onCreate_produces_the_frozen_schema_of_the_current_version() throws {
        let connection = try Connection(.inMemory)
        try DatabaseHelper(databaseUrl: nil).onCreate(database: connection)
        let version = DatabaseHelper.DATABASE_VERSION
        guard let frozenSchema = FrozenSchemas.snapshot(for: version) else {
            return XCTFail("No frozen schema snapshot for version \(version): add one to FrozenSchemas")
        }
        let actual = try schemaObjects(of: connection)
        for key in Set(actual.keys).union(frozenSchema.keys).sorted() {
            switch (frozenSchema[key], actual[key]) {
            case (nil, _?):
                XCTFail("Unexpected schema object \(key): \(actual[key] ?? "")")
            case (_?, nil):
                XCTFail("Missing schema object \(key)")
            case let (expected?, found?):
                XCTAssertEqual(found, expected, "Schema object \(key) differs from the frozen version-\(version) schema")
            default:
                break
            }
        }
    }

    func test_staged_version1_database_has_exactly_the_frozen_version1_schema() throws {
        var config = createMockConfig()
        config.databaseName = "frozen-v1-\(UUID().uuidString)"
        let path = try stageVersion1Database(config: config)
        addTeardownBlock {
            for candidate in [path] + SQLiteOpenHelper.sidecarSuffixes.map({ path + $0 }) {
                try? FileManager.default.removeItem(atPath: candidate)
            }
        }
        let connection = try Connection(path, readonly: true)
        XCTAssertEqual(try schemaObjects(of: connection), FrozenSchemas.v1)
        XCTAssertEqual(try connection.scalar("PRAGMA user_version") as? Int64, 1)
    }

    func test_staged_version1_database_keeps_seeded_rows() throws {
        var config = createMockConfig()
        config.databaseName = "seeded-v1-\(UUID().uuidString)"
        let rows = [
            StoredRow(module: "shared", key: "a", value: "\"abc\"", expiry: -1),
            StoredRow(module: "shared", key: "b", value: "\"def\"", expiry: 1234)
        ]
        let path = try stageVersion1Database(config: config, rows: rows)
        addTeardownBlock {
            for candidate in [path] + SQLiteOpenHelper.sidecarSuffixes.map({ path + $0 }) {
                try? FileManager.default.removeItem(atPath: candidate)
            }
        }
        XCTAssertEqual(try storedRows(atPath: path), rows)
        let connection = try Connection(path, readonly: true)
        XCTAssertEqual(try schemaObjects(of: connection), FrozenSchemas.v1)
        XCTAssertEqual(try storedState(atPath: path).userVersion, 1)
    }
}
