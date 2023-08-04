//
//  QueueSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 13/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

internal class QueueSchema {
    static let table = Table("queue")
    private static let dispatchId = Expression<String>("dispatch_id")
    private static let dispatcherId = Expression<Int>("dispatcher_id")

    static func createTable(database: Connection) throws {
        try database.run(table.create { table in
            table.column(dispatchId)
            table.column(dispatcherId)
            table.primaryKey(dispatchId, dispatcherId)
            table.foreignKey(dispatcherId, references: DispatcherSchema.table, Expression<Int>("id"), update: .cascade)
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
