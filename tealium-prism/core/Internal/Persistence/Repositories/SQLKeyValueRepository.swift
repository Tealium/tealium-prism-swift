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
    private let database: DatabaseConnection
    private let moduleId: Int64
    private let signposter: TealiumSignposter
    typealias Schema = ModuleStorageSchema

    init(dbProvider: DatabaseProviderProtocol, moduleId: Int64, signposter: TealiumSignposter) {
        self.database = dbProvider.database
        self.moduleId = moduleId
        self.signposter = signposter
    }

    func transactionally(execute block: (SQLKeyValueRepository) throws -> Void) throws {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Transaction").begin()
        defer { interval.end() }
        try self.database.transaction {
            try block(self)
        }
    }

    func get(key: String) -> DataItem? {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Get").begin(key)
        defer { interval.end() }
        guard let row = try? database.pluck(Schema.getValue(key: key, moduleId: self.moduleId)),
              let value = try? row.get(Schema.value) else {
            return nil
        }
        return DataItem(stringValue: value)
    }

    func getAll() -> DataObject {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "GetAll").begin()
        defer { interval.end() }
        guard let pairs = try? database.rows(Schema.getAllRows(moduleId: moduleId))
            .map({ row -> (String, DataInputConvertible) in
                (try row.get(Schema.key), DataItem(stringValue: try row.get(Schema.value)))
            }) else {
            return [:]
        }
        return DataObject(pairs: pairs)
    }

    func delete(key: String) throws -> Int {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Delete").begin(key)
        defer { interval.end() }
        return try database.run(Schema.delete(key: key, moduleId: moduleId))
    }

    @discardableResult
    func upsert(key: String, value: DataInput, expiry: Expiry) throws -> Int64 {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Upsert").begin(key)
        defer { interval.end() }
        return try database.run(Schema.insertOrReplace(moduleId: moduleId,
                                                       key: key,
                                                       value: try value.serialize(),
                                                       expiry: expiry))
    }

    func clear() throws -> Int {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Clear").begin()
        defer { interval.end() }
        return try database.run(Schema.clear(moduleId: moduleId))
    }

    func keys() -> [String] {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Keys").begin()
        defer { interval.end() }

        return (try? database.rows(Schema.getKeys(moduleId: moduleId)).map { try $0.get(Schema.key) }) ?? []
    }

    func count() -> Int {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Count").begin()
        defer { interval.end() }
        guard let count = try? database.scalar(Schema.getCount(moduleId: moduleId)) else {
            return 0
        }
        return count
    }

    func contains(key: String) -> Bool {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Contains").begin(key)
        defer { interval.end() }
        return (try? database.pluck(Schema.getValue(key: key, moduleId: self.moduleId))) != nil
    }

    func getExpiry(key: String) -> Expiry? {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "GetExpiry").begin(key)
        defer { interval.end() }
        guard let row = try? database.pluck(Schema.getValue(key: key, moduleId: self.moduleId)),
              let timestamp = try? row.get(Schema.expiry) else {
            return nil
        }
        return Expiry(timestamp: timestamp)
    }
}
