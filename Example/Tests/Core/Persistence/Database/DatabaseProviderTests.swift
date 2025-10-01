//
//  DatabaseProviderTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 15/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

final class DatabaseProviderTests: XCTestCase {
    var path = ""
    var config = mockConfig
    override func setUp() {
        path = (try? TealiumFileManager.getTealiumApplicationFolder().path) ?? ""
        try? TealiumFileManager.deleteAtPath(path: path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    override func tearDown() {
        try? TealiumFileManager.deleteAtPath(path: path)
    }

    func test_inMemory_db_is_created() throws {
        let database = XCTAssertNoThrowReturn(try DatabaseProvider.getInMemoryDatabase())
        XCTAssertNotNil(database)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    func test_persistent_db_is_created() throws {
        config.databaseName = "tealium"
        let database = DatabaseProvider.getPersistentDatabase(config: config)
        XCTAssertNotNil(database)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func test_downgraded_db_is_recreated() throws {
        DatabaseHelper.DATABASE_VERSION = 2
        // This simulates a past launch with a greater DB version
        var dbProviderV2: DatabaseProvider? = try DatabaseProvider(config: config)
        XCTAssertEqual(dbProviderV2?.database.userVersion, 2)
        DatabaseHelper.DATABASE_VERSION = 1
        dbProviderV2 = nil
        // This simulates the new launch after a downgrade
        let dbProviderV1 = try DatabaseProvider(config: config)
        XCTAssertEqual(dbProviderV1.database.userVersion, 1)
    }

    func test_created_database_is_persisted_by_default() throws {
        config.databaseName = "tealium"
        _ = try DatabaseProvider(config: config)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }
}
