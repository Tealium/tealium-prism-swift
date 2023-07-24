//
//  ModuleSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 6/13/23.
//

import Foundation
import SQLite

internal class ModuleSchema {
    static let table = Table("module")
    static let id = Expression<Int>("id")
    static let name = Expression<String>("name")
    
    static func createTable(db: Connection) throws {
        _ = try db.run(table.create { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(name, unique: true)
        })
    }
    
    static func getModule(moduleName: String) -> QueryType {
        return table.where(name == moduleName)
    }
    
    static func createModule(moduleName: String) -> Insert {
        return table.insert(self.name <- moduleName)
    }
}
