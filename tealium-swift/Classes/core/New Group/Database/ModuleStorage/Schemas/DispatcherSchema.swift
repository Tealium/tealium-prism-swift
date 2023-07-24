//
//  DispatcherSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 6/13/23.
//

import Foundation
import SQLite

internal class DispatcherSchema {
    static let table = Table("dispatcher")
    private static let id = Expression<Int>("id")
    private static let name = Expression<String>("name")
    private static let active = Expression<Bool>("active")
    
    static func createTable(db: Connection) throws {
        try db.run(table.create { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(name, unique: true)
            t.column(active, defaultValue: true)
        })
    }
}
