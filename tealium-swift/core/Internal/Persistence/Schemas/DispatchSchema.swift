//
//  DispatchSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 13/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

typealias Expression = SQLite.Expression

class DispatchSchema {
    static let table = Table("dispatch")
    static let uuid = Expression<String>("uuid")
    static let timestamp = Expression<Int64>("timestamp")
    static let dispatch = Expression<String>("dispatch")

    static let tableUUID = table[uuid]

    static func createTable(database: Connection) throws {
        try database.run(table.create { table in
            table.column(uuid, primaryKey: true)
            table.column(timestamp)
            table.column(dispatch)
        })
    }

    static func insert(dispatch: Dispatch) throws -> Insert {
        table.insert(or: .replace, [ Self.uuid <- dispatch.id,
                                    Self.timestamp <- dispatch.timestamp,
                                     Self.dispatch <- try dispatch.payload.serialize()])
    }

    static func deleteOldestDispatches(_ count: Int) throws -> Delete {
        table.order(DispatchSchema.timestamp)
            .limit(count)
            .delete()
    }

    static func deleteExpired(sentBefore timestamp: Int64) throws -> Delete {
        table.filter(DispatchSchema.timestamp < timestamp)
            .delete()
    }
}
