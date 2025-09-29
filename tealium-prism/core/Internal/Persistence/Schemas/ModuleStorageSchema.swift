//
//  ModuleStorageSchema.swift
//  tealium-prism
//
//  Created by Tyler Rister on 13/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

class ModuleStorageSchema {
    static let table = Table("module_storage")
    static let moduleId = Expression<Int64>("module_id")
    static let key = Expression<String>("key")
    static let value = Expression<String>("value")
    static let expiry = Expression<Int64>("expiry")

    static func createTable(database: Connection) throws {
        try database.run(table.create { table in
            table.column(moduleId)
            table.column(key)
            table.column(value)
            table.column(expiry)
            table.primaryKey(moduleId, key)
            table.foreignKey(moduleId, references: ModuleSchema.table, ModuleSchema.id, delete: .cascade)
        })
    }

    static func insertOrReplace(moduleId: Int64, key: String, value: String, expiry: Expiry) -> Insert {
        table.insert(or: .replace,
                     self.moduleId <- moduleId,
                     self.key <- key,
                     self.value <- value,
                     self.expiry <- expiry.expiryTime())
    }

    static func delete(key: String, moduleId: Int64) -> Delete {
        let deleteExpression: Expression<Bool> = self.key == key && self.moduleId == moduleId
        let query: QueryType = table.where(deleteExpression)
        return query.delete()
    }

    static func getExpired(request: ExpirationRequest, date: Date) -> QueryType {
        table.where(expired(request: request, date: date))
    }

    static func deleteExpired(request: ExpirationRequest, date: Date) -> Delete {
        table.where(expired(request: request, date: date)).delete()
    }

    static func getValue(key: String, moduleId: Int64) -> QueryType {
        let expression: Expression<Bool> = self.moduleId == moduleId && self.key == key && nonExpired()
        return table.where(expression)
    }

    static func getAllRows(moduleId: Int64) -> QueryType {
        table.where(self.moduleId == moduleId && nonExpired())
    }

    private static func nonExpired() -> Expression<Bool> {
        expiry < 0 || expiry > Date().unixTimeMilliseconds
    }

    private static func expired(request: ExpirationRequest, date: Date) -> Expression<Bool> {
        expiry == request.expiryTime || expiry < date.unixTimeMilliseconds && expiry > 0
    }

    static func getKeys(moduleId: Int64) -> QueryType {
        table.where(self.moduleId == moduleId && nonExpired())
    }

    static func getCount(moduleId: Int64) -> ScalarQuery<Int> {
        table.where(self.moduleId == moduleId && nonExpired()).count
    }

    static func clear(moduleId: Int64) -> Delete {
        table.where(self.moduleId == moduleId).delete()
    }
}
