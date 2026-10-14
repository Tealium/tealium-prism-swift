//
//  SchemaV1Tests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 12/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import SQLite
@testable import TealiumPrism
import XCTest

final class SchemaV1Tests: XCTestCase {

    private let expectedColumns: [String: Set<String>] = [
        SchemaV1.Module.table: [
            SchemaV1.Module.id,
            SchemaV1.Module.name
        ],
        SchemaV1.ModuleStorage.table: [
            SchemaV1.ModuleStorage.moduleId,
            SchemaV1.ModuleStorage.key,
            SchemaV1.ModuleStorage.value,
            SchemaV1.ModuleStorage.expiry
        ],
        SchemaV1.Dispatch.table: [
            SchemaV1.Dispatch.uuid,
            SchemaV1.Dispatch.timestamp,
            SchemaV1.Dispatch.dispatch
        ],
        SchemaV1.Queue.table: [
            SchemaV1.Queue.dispatchId,
            SchemaV1.Queue.processor
        ]
    ]

    func test_schemaV1_names_equal_the_frozen_version1_schema() throws {
        let connection = try Connection(.inMemory)
        for statement in try XCTUnwrap(FrozenSchemas.createStatements(for: 1)) {
            try connection.execute(statement)
        }
        let rows = try connection.prepare("""
            SELECT m.name, p.name FROM sqlite_master m JOIN pragma_table_info(m.name) p
            WHERE m.type = 'table' AND m.name NOT LIKE 'sqlite_%'
            """)
        var frozen = [String: Set<String>]()
        for row in rows {
            let table = try XCTUnwrap(row[0] as? String)
            let column = try XCTUnwrap(row[1] as? String)
            frozen[table, default: []].insert(column)
        }
        XCTAssertEqual(frozen, expectedColumns)
    }
}
