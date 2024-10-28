//
//  VisitorStorageTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 09/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class VisitorStorageTests: XCTestCase {
    let databaseProvider = MockDatabaseProvider()
    func createStorage() throws -> VisitorStorage {
        let storeProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
        return try VisitorStorage(storage: storeProvider.getModuleStore(name: "visitor"))
    }
    var storage: VisitorStorage!
    override func setUp() {
        storage = XCTAssertNoThrowReturn(try createStorage())
    }

    func test_visitorId_is_null_at_the_start() {
        XCTAssertNil(storage.visitorId)
    }

    func test_visitorId_returns_visitorId_after_changeVisitor() throws {
        try storage.changeVisitor("aVisitor")
        XCTAssertEqual(storage.visitorId, "aVisitor")
    }

    func test_visitorId_returns_visitorId_after_changeVisitor_withIdentity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.visitorId, "aVisitor")
    }

    func test_currentIdentity_is_null_at_the_start() {
        XCTAssertNil(storage.currentIdentity)
    }

    func test_currentIdentity_is_null_after_changeVisitor() throws {
        try storage.changeVisitor("aVisitor")
        XCTAssertNil(storage.currentIdentity)
    }

    func test_currentIdentity_returns_identity_after_changeVisitor_withIdentity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.currentIdentity, "anIdentity")
    }

    func test_changeVisitor_withIdentity_replaces_both_visitorId_and_currentIdentity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.visitorId, "aVisitor")
        XCTAssertEqual(storage.currentIdentity, "anIdentity")
        try storage.changeVisitor("newVisitor", withIdentity: "anotherIdentity")
        XCTAssertEqual(storage.visitorId, "newVisitor")
        XCTAssertEqual(storage.currentIdentity, "anotherIdentity")
    }

    func test_changeVisitor_replaces_visitorId_and_associates_identity_with_current_visitorId() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.getKnownVisitorId(identity: "anIdentity"), "aVisitor")
        try storage.changeVisitor("newVisitor")
        XCTAssertEqual(storage.getKnownVisitorId(identity: "anIdentity"), "newVisitor")
    }

    func test_getKnownVisitorId_returns_previous_visitorIds() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        try storage.changeVisitor("newVisitor", withIdentity: "anotherIdentity")
        XCTAssertEqual(storage.getKnownVisitorId(identity: "anIdentity"), "aVisitor")
    }

    func test_getKnownVisitorId_returns_visitorId_after_changeVisitor_withIdentity() throws {
        try storage.changeVisitor("aVisitor", withIdentity: "anIdentity")
        XCTAssertEqual(storage.getKnownVisitorId(identity: "anIdentity"), "aVisitor")
    }

    func test_clear_removes_all_data_and_inserts_new_visitorId() throws {
        try storage.changeVisitor("aVisitor1", withIdentity: "anIdentity1")
        try storage.changeVisitor("aVisitor2", withIdentity: "anIdentity2")
        try storage.changeVisitor("aVisitor3", withIdentity: "anIdentity3")
        try storage.clear(settingNewVisitorId: "newVisitor")
        XCTAssertNil(storage.getKnownVisitorId(identity: "anIdentity1"))
        XCTAssertNil(storage.getKnownVisitorId(identity: "anIdentity2"))
        XCTAssertNil(storage.getKnownVisitorId(identity: "anIdentity3"))
        XCTAssertNil(storage.currentIdentity)
        XCTAssertEqual(storage.visitorId, "newVisitor")
    }
}
