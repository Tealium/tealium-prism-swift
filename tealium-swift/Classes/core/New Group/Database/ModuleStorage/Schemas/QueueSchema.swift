//
//  QueueSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 6/13/23.
//

import Foundation
import SQLite

internal class QueueSchema {
    static let table = Table("queue")
    private static let dispatchId = Expression<String>("dispatch_id")
    private static let dispatcherId = Expression<Int>("dispatcher_id")
    
    static func createTable(db: Connection) throws {
        try db.run(table.create { t in
            t.column(dispatchId)
            t.column(dispatcherId)
            t.primaryKey(dispatchId, dispatcherId)
            t.foreignKey(dispatcherId, references: DispatcherSchema.table, Expression<Int>("id"), update: .cascade)
        })
    }
    
    static func getTriggerToRemoveProcessedDispatches() -> String {
        return """
                CREATE TRIGGER queue_remove_processed_dispatches
                    AFTER DELETE ON queue
                BEGIN
                    DELETE FROM dispatch
                    WHERE NOT EXISTS (
                        SELECT dispatch_id
                          FROM queue
                          WHERE dispatch_id = dispatch.id
                    );
                END;
        """
    }
}
