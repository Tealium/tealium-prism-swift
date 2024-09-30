//
//  SQLQueueRepository.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

class SQLQueueRepository: QueueRepository {
    private let database: Connection
    var size: Int {
        (try? database.scalar(DispatchSchema.table.count)) ?? 0
    }
    private(set) var maxQueueSize: Int
    private(set) var expiration: TimeFrame
    init(dbProvider: DatabaseProviderProtocol, maxQueueSize: Int, expiration: TimeFrame) {
        self.database = dbProvider.database
        self.maxQueueSize = maxQueueSize
        self.expiration = expiration
    }

    func deleteQueues(forProcessorsNotIn processors: [String]) throws {
        try database.transaction {
            try database.run(QueueSchema.deleteDispatches(forProcessorsNotContainedIn: processors))
        }
    }

    func storeDispatches(_ dispatches: [TealiumDispatch], enqueueingFor processors: [String]) throws {
        guard !dispatches.isEmpty && !processors.isEmpty else { // Enqueuing no dispatches or for no processors is not allowed
            return
        }
        try database.transaction {
            try storeDispatches(dispatches, enueueingFor: processors)
        }
    }

    private func storeDispatches(_ dispatches: [TealiumDispatch], enueueingFor processors: [String]) throws {
        try createSpaceIfNecessary(for: dispatches.count)
        try dispatches
            .suffix(maxQueueSize)
            .forEach { dispatch in
                try database.run(DispatchSchema.insert(dispatch: dispatch))
                /* Enqueue needs to be run immediately after each dispatch insert or,
                 in case of replace, the trigger is invoked and all previously inserted dispatches
                 get deleted due to no processors being in the queue for that event */
                try enqueueDispatch(dispatch.id, for: processors)
            }
    }

    private func enqueueDispatch(_ dispatchUUID: String, for processors: [String]) throws {
        for processor in processors {
            try database.run(QueueSchema.insertDispatch(dispatchUUID, for: processor))
        }
    }

    func getQueuedDispatches(for processor: String, limit: Int?, excluding: [String] = []) -> [TealiumDispatch] {
        let filterExpiredExpression: Expression<Bool> = DispatchSchema.timestamp > getExpiryTimestamp(expiration: expiration)
        let dispatchTable: QueryType = DispatchSchema.table
        let query = dispatchTable.where(!excluding.contains(DispatchSchema.uuid))
            .join(.inner,
                  QueueSchema.table,
                  on: DispatchSchema.tableUUID == QueueSchema.tableDispatchId && QueueSchema.tableProcessor == processor)
            .filter(filterExpiredExpression)
            .order(DispatchSchema.timestamp)
            .limit(limit)
        return getDispatches(query: query)
    }

    private func getDispatches(query: QueryType) -> [TealiumDispatch] {
        guard let rows = try? database.prepare(query) else {
            return []
        }
        return rows.compactMap { row -> TealiumDispatch? in
            guard let eventData: DataObject = try? row[DispatchSchema.dispatch].deserializeCodable() else {
                return nil
            }
            return TealiumDispatch(eventData: eventData,
                                   id: row[DispatchSchema.tableUUID],
                                   timestamp: row[DispatchSchema.timestamp])
        }
    }

    func deleteDispatches(_ dispatchUUIDs: [String], for processor: String) throws {
        try database.transaction {
            try database.run(QueueSchema.deleteDispatches(dispatchUUIDs, for: processor))
        }
    }

    func deleteAllDispatches(for processor: String) throws {
        try database.transaction {
            try database.run(QueueSchema.deleteAllDispatches(for: processor))
        }
    }

    func resize(newSize: Int) throws {
        maxQueueSize = newSize
        try createSpaceIfNecessary(for: 0)
    }

    func setExpiration(_ expiration: TimeFrame) throws {
        if expiration != self.expiration {
            defer { self.expiration = expiration }
            try self.deleteExpired(expiration: min(self.expiration, expiration))
        }
    }

    private func deleteExpired(expiration: TimeFrame) throws {
        try database.run(DispatchSchema.deleteExpired(sentBefore: getExpiryTimestamp(expiration: expiration)))
    }

    private func createSpaceIfNecessary(for size: Int) throws {
        let spaceRequired = spaceRequired(incomingCount: size)
        guard spaceRequired > 0 else {
            return
        }
        try database.run(DispatchSchema.deleteLatestDispatches(spaceRequired))
    }

    private func spaceRequired(incomingCount: Int) -> Int {
        guard maxQueueSize >= 0 else {
            return 0
        }
        return size + incomingCount - maxQueueSize
    }

    /**
     * Returns the oldest unix timestamp (in milliseconds) that would be considered not-expired.
     */
    private func getExpiryTimestamp(expiration: TimeFrame) -> Int64 {
        guard let expiryDate = expiration.dateBefore() else {
            return .max
        }
        return expiryDate.unixTimeMillisecondsInt
    }
}
