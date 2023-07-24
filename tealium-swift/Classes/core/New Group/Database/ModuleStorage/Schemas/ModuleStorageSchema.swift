//
//  ModuleStorageSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 6/13/23.
//

import Foundation
import SQLite

internal class ModuleStorageSchema {
    static let table = Table("module_storage")
    static let moduleId = Expression<Int>("module_id")
    static let key = Expression<String>("key")
    static let value = Expression<String>("value")
    static let expiry = Expression<Double>("expiry")
    
    static func createTable(db: Connection) throws {
        try db.run(table.create { t in
            t.column(moduleId, references: ModuleSchema.table, Expression<Int>("id"))
            t.column(key)
            t.column(value)
            t.column(expiry)
            t.primaryKey(moduleId, key)
        })
    }
    
    static func insertOrReplace(moduleId: Int, key: String, value: String, expiry: Expiry) -> Insert {
        return table.insert(or: .replace,
                            self.moduleId <- moduleId,
                            self.key <- key,
                            self.value <- value,
                            self.expiry <- expiry.expiryTime())
    }
    
    static func delete(key: String, moduleId: Int) -> Delete {
        return table.filter(self.key == key && self.moduleId == moduleId).delete()
    }
    
    static func getValue(key: String, moduleId: Int) -> QueryType {
        return table.where(self.moduleId == moduleId && self.key == key)
    }
    
    static func getAllRows(moduleId: Int) -> QueryType {
        return table.where(self.moduleId == moduleId)
    }
    
    static func getKeys(moduleId: Int) -> QueryType {
        return table.where(self.moduleId == moduleId)
    }
    
    static func getCount(moduleId: Int) -> ScalarQuery<Int> {
        return table.where(self.moduleId == moduleId).count
    }
}
