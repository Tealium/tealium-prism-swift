//
//  DispatcherSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 13/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

internal class DispatcherSchema {
    static let table = Table("dispatcher")
    private static let id = Expression<Int>("id")
    private static let name = Expression<String>("name")
    private static let active = Expression<Bool>("active")

    static func createTable(database: Connection) throws {
        try database.run(table.create { table in
            table.column(id, primaryKey: .autoincrement)
            table.column(name, unique: true)
            table.column(active, defaultValue: true)
        })
    }
}
