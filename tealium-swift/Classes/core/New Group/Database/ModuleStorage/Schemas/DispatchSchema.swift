//
//  DispatchSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 6/13/23.
//

import Foundation
import SQLite

internal class DispatchSchema {
    static let table = Table("dispatch")
    private static let id = Expression<Int>("id")
    private static let timestamp = Expression<Date>("timestamp")
    private static let dispatch = Expression<String>("dispatch")
    
    static func createtable(db: Connection) throws {
        try db.run(table.create{ t in
            t.column(id, primaryKey: .autoincrement)
            t.column(timestamp)
            t.column(dispatch)
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
