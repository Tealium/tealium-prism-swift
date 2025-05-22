//
//  QueueRepository.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 17/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A repository class that holds `Dispatch`es and queues them in separate processor's queues.
protocol QueueRepository {

    /**
     * Returns the current size of the queue considering all dispatches that have not been fully
     * processed.
     *
     * If a dispatch has remained unprocessed by any of the `processors`s it is registered for, then
     * this property will include it in the returned size.
     *
     * - Returns: The number of `dispatch`es that are not completely processed.
     */
    var size: Int { get }

    /**
     * Deletes all the queues for `processors` not listed in the provided `processors`.
     *
     * - Parameters:
     *    - processors: The `processors` allowed to have dispatches queued for processing.
     */
    func deleteQueues(forProcessorsNotIn processors: [String]) throws

    /**
     * Adds the `dispatch`es to the queue, creating entries for all `processor`s that are provided.
     *
     * - Parameters:
     *    - dispatches: The `dispatch`es to persist in case we can't yet send them.
     *    - processors: The `processor`s that need to process these dispatches.
     */
    func storeDispatches(_ dispatches: [Dispatch], enqueueingFor processors: [String]) throws

    /**
     * Returns the oldest `count` dispatches for the given `processor`.
     *
     * - Parameters:
     *    - processor: The `processor` for which to retrieve the dispatches.
     *    - limit: The maximum number of queued `Dispatch`es to return. If value is nil, then all entries will be returned.
     *    - excluding: The list of `Dispatch`es UUIDs to exclude.
     */
    func getQueuedDispatches(for processor: String, limit: Int?, excluding: [String]) -> [Dispatch]

    /**
     * Removes the given `Dispatch`es from the queue, only for the given `processor`.
     *
     *
     * - Parameters:
     *    - dispatchUUIds: The `Dispatch` IDs to remove from the queue.
     *    - processor: The `processor` from which the dispatches needs to be removed form.
     */
    func deleteDispatches(_ dispatchUUIds: [String], for processor: String) throws

    /**
     * Removes all the `dispatches` from the queue, only for the given `processor`.
     *
     *
     * - Parameters:
     *    - processor: The `processor` from which the dispatches needs to be removed form.
     */
    func deleteAllDispatches(for processor: String) throws

    /**
     * Updates the maximum queue size, deleting the oldest entries where necessary.
     *
     * - Parameters:
     *    - newSize: The new maximum size that the queue can extend to.
     */
    func resize(newSize: Int) throws

    /**
     * Changes the current expiration and deletes all the expired items according to both the new and old expiration.
     *
     * - Parameters:
     *   - expiration: The `TimeFrame` used to validate if the currently enqueued items are expired or not.
     */
    func setExpiration(_ expiration: TimeFrame) throws
}
