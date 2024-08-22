//
//  QueueSchema.swift
//  tealium-swift
//
//  Created by Tyler Rister on 13/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

class QueueSchema {
    static let table = Table("queue")
    static let dispatchId = Expression<String>("dispatch_id")
    static let processor = Expression<String>("processor")

    static let tableDispatchId = table[dispatchId]
    static let tableProcessor = table[processor]

    static func createTable(database: Connection) throws {
        try database.run(table.create { table in
            table.column(dispatchId)
            table.column(processor)
            table.primaryKey(dispatchId, processor)
            table.foreignKey(dispatchId, references: DispatchSchema.table, DispatchSchema.uuid, delete: .cascade)

        })
    }

    static func getTriggerToRemoveProcessedDispatches() -> String {
        return """
                CREATE TRIGGER queue_remove_processed_dispatches
                    AFTER DELETE ON queue
                BEGIN
                    DELETE FROM dispatch
                    WHERE NOT EXISTS (
                        SELECT processor
                          FROM queue
                          WHERE dispatch_id = dispatch.uuid
                    );
                END;
        """
    }

    static func insertDispatch(_ dispatchUUID: String, for processor: String) -> Insert {
        table.insert([ Self.dispatchId <- dispatchUUID,
                       Self.processor <- processor ])
    }

    static func deleteDispatches(forProcessorsNotContainedIn processors: [String]) -> Delete {
        table.filter(!processors.contains(processor)).delete()
    }

    static func deleteDispatches(_ dispatchIds: [String], for processor: String) -> Delete {
        QueueSchema.table
            .where(dispatchIds.contains(QueueSchema.dispatchId) && QueueSchema.processor == processor)
            .delete()
    }

    static func deleteAllDispatches(for processor: String) -> Delete {
        QueueSchema.table
            .where(QueueSchema.processor == processor)
            .delete()
    }
}
