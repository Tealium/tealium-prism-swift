//
//  V1ToV2Tests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 12/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

final class V1ToV2Tests: XCTestCase {
    typealias Fixture = Version1VisitorFixture

    /// The test account's folder. Only this is cleaned up, not the whole `tealium-prism` one, which unsandboxed apps share on macOS.
    var folder = ""
    var config = mockConfig

    override func setUp() {
        folder = (try? TealiumFileManager.getTealiumApplicationFolder().appendingPathComponent(config.account).path) ?? ""
        try? TealiumFileManager.deleteAtPath(path: folder)
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder))
    }

    override func tearDown() {
        try? TealiumFileManager.deleteAtPath(path: folder)
    }

    // MARK: - Moving data

    func test_moves_visitor_id_owner_identity_and_every_association() throws {
        let path = try stage(rows: Fixture.all)
        try upgrade(path: path)
        let expected = Fixture.visitorState.map(moved) + Fixture.otherSharedRows + Fixture.lookAlikes
        XCTAssertEqual(try storedRows(atPath: path), sorted(expected))
        XCTAssertEqual(try storedState(atPath: path).userVersion, 2)
    }

    func test_does_not_move_association_shaped_rows_without_a_visitor_id() throws {
        let path = try stage(rows: Fixture.withoutVisitorId)
        try upgrade(path: path)
        let expected = Fixture.withoutVisitorId
        XCTAssertEqual(try storedRows(atPath: path), sorted(expected))
        let state = try storedState(atPath: path)
        XCTAssertEqual(state.modules, ["marker", Fixture.sharedModule])
        XCTAssertEqual(state.userVersion, 2)
    }

    func test_moves_a_visitor_id_without_an_identity() throws {
        let path = try stage(rows: Fixture.anonymous)
        let upgraded = try upgrade(path: path)
        XCTAssertEqual(try storedRows(atPath: path), Fixture.anonymous.map(moved))
        let storage = try visitorStorage(on: upgraded)
        XCTAssertEqual(storage.visitorId, Fixture.currentVisitorId)
        XCTAssertNil(storage.ownerIdentity)
    }

    func test_legacy_rows_replace_conflicting_rows_in_an_existing_visitor_id_store() throws {
        let existing = [
            StoredRow(module: V1ToV2.targetModuleName, key: V1ToV2.targetKeyVisitorId, value: "\"unreleased\"", expiry: 1234),
            StoredRow(module: V1ToV2.targetModuleName, key: "other", value: "\"kept\"", expiry: -1)
        ]
        let path = try stage(rows: existing + Fixture.all)
        try upgrade(path: path)
        let visitorRows = try storedRows(atPath: path).filter { $0.module == V1ToV2.targetModuleName }
        XCTAssertEqual(visitorRows, sorted(Fixture.visitorState.map(moved) + [existing[1]]))
    }

    func test_moves_nothing_without_a_shared_store() throws {
        let path = try stage()
        try upgrade(path: path)
        XCTAssertEqual(try storedRows(atPath: path), [])
        let state = try storedState(atPath: path)
        XCTAssertEqual(state.modules, ["marker"])
        XCTAssertEqual(state.userVersion, 2)
    }

    func test_is_idempotent() throws {
        let path = try stage(rows: Fixture.all)
        let upgraded = try upgrade(path: path)
        let once = try storedRows(atPath: path)
        try V1ToV2().upgrade(upgraded)
        XCTAssertEqual(try storedRows(atPath: path), once)
        // The guard now finds no `visitorId`; the UPDATE itself must also match nothing when run on its own.
        try upgraded.execute(V1ToV2.moveVisitorRows)
        XCTAssertEqual(try storedRows(atPath: path), once)
        XCTAssertEqual(once.filter { $0.module == V1ToV2.targetModuleName }.count, 5)
    }

    // MARK: - Structure

    private func structure(of connection: Connection) throws -> [String] {
        let tables = try connection.prepare("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
            .compactMap { $0[0] as? String }
        var description = [String]()
        for table in tables {
            for pragma in ["table_info", "index_list", "foreign_key_list"] {
                for row in try connection.prepare("PRAGMA \(pragma)(\"\(table)\")") {
                    description.append("\(table).\(pragma): " + row.map { "\($0 ?? "NULL")" }.joined(separator: "|"))
                }
            }
        }
        for row in try connection.prepare("SELECT name, sql FROM sqlite_master WHERE type = 'trigger' ORDER BY name") {
            description.append("trigger: " + row.map { "\($0 ?? "NULL")" }.joined(separator: "|"))
        }
        return description
    }

    func test_upgraded_file_is_structurally_equal_to_a_fresh_install() throws {
        let path = try stage(rows: Fixture.all)
        let upgraded = try upgrade(path: path)
        let fresh = try DatabaseHelper(databaseUrl: nil, version: 2, upgrades: [V1ToV2()]).getDatabase()
        let freshStructure = try structure(of: fresh)
        XCTAssertFalse(freshStructure.isEmpty)
        XCTAssertEqual(try structure(of: upgraded), freshStructure)
    }

    // MARK: - Real reader

    func test_visitor_storage_reads_the_moved_data() throws {
        let path = try stage(rows: Fixture.all)
        let storage = try visitorStorage(on: try upgrade(path: path))
        XCTAssertEqual(storage.visitorId, Fixture.currentVisitorId)
        XCTAssertEqual(storage.ownerIdentity, Fixture.hashA)
        let known = [Fixture.hashA: Fixture.currentVisitorId,
                     Fixture.hashB: Fixture.olderVisitorIdB,
                     Fixture.hashC: Fixture.olderVisitorIdC]
        for (hash, visitorId) in known {
            XCTAssertEqual(storage.getKnownVisitorId(identity: hash), visitorId)
        }
    }

    // MARK: - Failure

    func test_failed_upgrade_rolls_back_the_move() throws {
        let path = try stage(rows: Fixture.all)
        let seeded = try storedRows(atPath: path)
        let helper = DatabaseHelper(databaseUrl: URL(fileURLWithPath: path), version: 3, upgrades: [
            V1ToV2(),
            TestUpgrade(targetVersion: 3) { _ in throw StepError() }
        ])
        XCTAssertThrowsError(try helper.getDatabase())
        XCTAssertEqual(try storedRows(atPath: path), seeded)
        let state = try storedState(atPath: path)
        XCTAssertEqual(state.userVersion, 1)
        // The `VisitorId` module row inserted by the step is rolled back too.
        XCTAssertEqual(state.modules, ["marker", "shared"])
    }

    // MARK: - Default open

    func test_default_open_moves_visitor_data() throws {
        let path = try stage(rows: Fixture.all)
        let logger = MockLogger()
        var persistenceLogs = [String]()
        let subscription = logger.handler.onLogged.subscribe { event in
            if event.category == LogCategory.persistence {
                persistenceLogs.append(event.message)
            }
        }
        defer { subscription.dispose() }
        _ = try DatabaseProvider.openDatabase(config: config, logger: logger)
        XCTAssertEqual(persistenceLogs, [])
        XCTAssertEqual(try storedState(atPath: path).userVersion, Int64(DatabaseHelper.DATABASE_VERSION))
        let visitorRows = try storedRows(atPath: path).filter { $0.module == V1ToV2.targetModuleName }
        XCTAssertEqual(visitorRows, sorted(Fixture.visitorState.map(moved)))
    }

    /// The whole SDK on a 0.6.0 file: the public visitor id API returns the id that file held.
    func test_sdk_started_on_a_version1_file_exposes_the_stored_visitor_id() throws {
        _ = try stage(rows: Fixture.all)
        config.networkClient = MockNetworkClient(result: .success(.successful()))
        let instanceManager = TealiumInstanceManager(queue: .worker)
        let teal = instanceManager.create(config: config)
        addTeardownBlock {
            teal.shutdown()
            instanceManager.queue.dispatchQueue.sync {
                instanceManager.instances.removeAll()
            }
        }
        let received = expectation(description: "The current visitor id is received")
        var visitorId: String?
        teal.visitorId.current().subscribe { result in
            visitorId = try? result.get()
            received.fulfill()
        }
        waitOnQueue(queue: instanceManager.queue, timeout: 10)
        XCTAssertEqual(visitorId, Fixture.currentVisitorId)
    }

    // MARK: - Pins

    /// If a later version renames these, that version adds its own step, and this test then pins the frozen values.
    func test_target_literals_match_the_live_constants() {
        XCTAssertEqual(V1ToV2.targetModuleName, Modules.Types.visitorId)
        XCTAssertEqual(V1ToV2.targetKeyVisitorId, VisitorStorage.Keys.visitorId)
        XCTAssertEqual(V1ToV2.targetKeyOwnerIdentity, VisitorStorage.Keys.ownerIdentity)
        XCTAssertEqual(V1ToV2.targetPrefixIdentity, VisitorStorage.Keys.identityPrefix)
    }

    func test_source_module_name_matches_the_shared_store() throws {
        let provider = MockDatabaseProvider()
        let moduleStoreProvider = ModuleStoreProvider(databaseProvider: provider,
                                                      modulesRepository: SQLModulesRepository(dbProvider: provider))
        _ = try moduleStoreProvider.getSharedDataStore()
        let names = try provider.database.prepare("SELECT name FROM module").compactMap { $0[0] as? String }
        XCTAssertTrue(names.contains(V1ToV2.sourceModuleName))
    }

    // MARK: - Helpers

    private func stage(rows: [StoredRow] = []) throws -> String {
        config.databaseName = "v1"
        return try stageVersion1Database(config: config, rows: rows)
    }

    /// Opens (and so upgrades) the file at `path` through the real helper. The connection closes when it is released.
    @discardableResult
    private func upgrade(path: String) throws -> Connection {
        try DatabaseHelper(databaseUrl: URL(fileURLWithPath: path), version: 2, upgrades: [V1ToV2()]).getDatabase()
    }

    private func visitorStorage(on connection: Connection) throws -> VisitorStorage {
        let provider = MockDatabaseProvider(database: connection)
        let moduleStoreProvider = ModuleStoreProvider(databaseProvider: provider,
                                                      modulesRepository: SQLModulesRepository(dbProvider: provider))
        return VisitorStorage(storage: try moduleStoreProvider.getModuleStore(name: Modules.Types.visitorId))
    }

    private func sorted(_ rows: [StoredRow]) -> [StoredRow] {
        rows.sorted { ($0.module, $0.key) < ($1.module, $1.key) }
    }

    private func moved(_ row: StoredRow) -> StoredRow {
        let key: String
        switch row.key {
        case "visitorId": key = V1ToV2.targetKeyVisitorId
        case "currentIdentity": key = V1ToV2.targetKeyOwnerIdentity
        default: key = V1ToV2.targetPrefixIdentity + row.key
        }
        return StoredRow(module: V1ToV2.targetModuleName, key: key, value: row.value, expiry: row.expiry)
    }

}
