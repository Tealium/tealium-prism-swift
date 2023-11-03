//
//  DatabaseProviderTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 15/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumSwift
import XCTest

final class DatabaseProviderTests: XCTestCase {
    var path = ""

    override func setUp() {
        path = (try? TealiumFileManager.getTealiumApplicationFolder().path) ?? ""
        try? TealiumFileManager.deleteAtPath(path: path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    override func tearDown() {
        try? TealiumFileManager.deleteAtPath(path: path)
    }

    func test_inMemory_db_is_created() throws {
        let database = XCTAssertNoThrowReturn(try DatabaseProvider.getInMemoryDatabase(settings: CoreSettings(coreDictionary: [:])))
        XCTAssertNotNil(database)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }

    func test_persistent_db_is_created() throws {
        let database = DatabaseProvider.getPersistentDatabase(settings: CoreSettings(coreDictionary: [:]))
        XCTAssertNotNil(database)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func test_downgraded_db_is_recreated() throws {
        DatabaseHelper.DATABASE_VERSION = 2
        let dbProviderV2 = try DatabaseProvider(settings: CoreSettings(coreDictionary: [:]))
        XCTAssertEqual(dbProviderV2.database.userVersion, 2)
        DatabaseHelper.DATABASE_VERSION = 1
        let dbProviderV1 = try DatabaseProvider(settings: CoreSettings(coreDictionary: [:]))
        XCTAssertEqual(dbProviderV1.database.userVersion, 1)
        XCTAssertNil(dbProviderV2.database.userVersion, "Old DB connection should be unusable")
        XCTAssertThrowsError(try dbProviderV2.database.run(ModuleSchema.createModule(moduleName: "test")), "Old DB connection should be unusable")
        XCTAssertThrowsError(try dbProviderV2.database.pluck(ModuleSchema.getModule(moduleName: "test")), "Old DB connection should be unusable")
    }

    func test_created_database_is_persisted_by_default() throws {
        _ = try DatabaseProvider(settings: CoreSettings(coreDictionary: [:]))
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }
}
