//
//  SQLKeyValueRepository.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

final class SQLKeyValueRepository: KeyValueRepository {
    private let database: Connection
    private let moduleId: Int64
    typealias Schema = ModuleStorageSchema

    init(dbProvider: DatabaseProviderProtocol, moduleId: Int64) {
        self.database = dbProvider.database
        self.moduleId = moduleId
    }

    func transactionally(execute block: (SQLKeyValueRepository) throws -> Void) throws {
        try database.transaction {
            try block(self)
        }
    }

    func get(key: String) -> DataItem? {
        guard let row = try? database.pluck(Schema.getValue(key: key, moduleId: self.moduleId)) else {
            return nil
        }
        return DataItem(stringValue: row[Schema.value])
    }

    func getAll() -> DataObject {
        guard let rows = try? database.prepare(Schema.getAllRows(moduleId: moduleId)) else {
            return [:]
        }
        return DataObject(pairs: rows.map { row in
            (row[Schema.key], DataItem(stringValue: row[Schema.value]))
        })
    }

    func delete(key: String) throws -> Int {
        try database.run(Schema.delete(key: key, moduleId: moduleId))
    }

    @discardableResult
    func upsert(key: String, value: DataInput, expiry: Expiry) throws -> Int64 {
        try database.run(Schema.insertOrReplace(moduleId: moduleId,
                                                key: key,
                                                value: try value.serialize(),
                                                expiry: expiry))
    }

    func clear() throws -> Int {
        try database.run(Schema.clear(moduleId: moduleId))
    }

    func keys() -> [String] {
        guard let mapRowIterator = try? database.prepareRowIterator(Schema.getKeys(moduleId: moduleId)),
              let keys = try? mapRowIterator.map({ $0[Schema.key] }) else {
            return []
        }
        return keys
    }

    func count() -> Int {
        guard let count = try? database.scalar(Schema.getCount(moduleId: moduleId)) else {
            return 0
        }
        return count
    }

    func contains(key: String) -> Bool {
        (try? database.pluck(Schema.getValue(key: key, moduleId: self.moduleId))) != nil
    }

    func getExpiry(key: String) -> Expiry? {
        guard let row = try? database.pluck(Schema.getValue(key: key, moduleId: self.moduleId)) else {
            return nil
        }
        return Expiry(timestamp: row[Schema.expiry])
    }
}
