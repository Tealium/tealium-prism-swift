//
//  ModuleSchema.swift
//  tealium-prism
//
//  Created by Tyler Rister on 6/13/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

class ModuleSchema {
    static let table = Table("module")
    static let id = Expression<Int64>("id")
    static let name = Expression<String>("name")

    static func createTable(database: Connection) throws {
        _ = try database.run(table.create { table in
            table.column(id, primaryKey: .autoincrement)
            table.column(name, unique: true)
        })
    }

    static func getModule(moduleName: String) -> QueryType {
        getModules().where(name == moduleName)
    }

    static func getModules() -> QueryType {
        table
    }

    static func createModule(moduleName: String) -> Insert {
        table.insert(self.name <- moduleName)
    }
}
