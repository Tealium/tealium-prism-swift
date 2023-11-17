//
//  DispatchSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 13/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

class DispatchSchema {
    static let table = Table("dispatch")
    private static let id = Expression<Int>("id")
    private static let timestamp = Expression<Date>("timestamp")
    private static let dispatch = Expression<String>("dispatch")

    static func createtable(database: Connection) throws {
        try database.run(table.create { table in
            table.column(id, primaryKey: .autoincrement)
            table.column(timestamp)
            table.column(dispatch)
        })
    }

    static func getTriggerForAddToQueue() -> String {
        return """
                CREATE TRIGGER dispatch_add_to_queue
                    AFTER INSERT ON dispatch
                    FOR EACH ROW
                BEGIN
                    INSERT INTO queue
                        SELECT NEW.id, dispatcher.id
                        FROM dispatcher
                        WHERE dispatcher.active = true;
                END;
            """
    }
}
