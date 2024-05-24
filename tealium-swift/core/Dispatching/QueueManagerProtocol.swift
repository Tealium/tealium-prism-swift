//
//  QueueManagerProtocol.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 08/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A manager that stores `TealiumDispatch`es in separate queues per each `processor` and keeps track of the one that are currently inflight.
public protocol QueueManagerProtocol {
    /// Observable that emits an event with the `processor`s for which a `TealiumDispatch` is enqueued.
    var onEnqueuedDispatchesForProcessors: TealiumObservable<[String]> { get }

    /**
     * Returns an observable that emits an event every time the amount of inflight `TealiumDispatch`es for a specific processor changes.
     *
     * - parameter processor: The `processor` for which to listen for the events count change
     *
     * - returns: A `TealiumObservable<Int>` that emits events with the count of `TealiumDispatch`es that are currently inflight.
     */
    func onInflightDispatchesCount(for processor: String) -> TealiumObservable<Int>

    /**
     * Returns the `TealiumDispatch`es in the queue, up to an optional limit, excluding the current inflight events.
     *
     * - Parameters:
     *  - processor: The `processor` from which `TealiumDispatch`es need to be dequeued from.
     *  - limit: The optional maximum amount of dispatches to dequeue.
     *
     * - returns: A list of `TealiumDispatch`es, ordered by timestamp, starting from the latest inflight dispatch.
     */
    func getQueuedDispatches(for processor: String, limit: Int?) -> [TealiumDispatch]

    /**
     * Stores the `TealiumDispatch`es for all the `processor`s' queues.
     *
     * This will automatically replace existing `TealiumDispatch`es with the same IDs and remove all previous `processor`s.
     * Empty dispatches and/or empty processors result in a no-op.
     *
     * - Parameters:
     *  - dispatches: The `TealiumDispatch`es that will be stored in the queues
     *  - processors: The `processor`s for which to store the dispatches in the queue.
     */
    func storeDispatches(_ dispatches: [TealiumDispatch], enqueueingFor processors: [String])

    /**
     * Deletes the provided `TealiumDispatches` from the queue and from the list of inflight for the given `processor`.
     *
     * - Parameters:
     *  - dispatchUUIDs: A list of `TealiumDispatch` UUIDs to delete from the queue and from the inflights
     *  - processor: The `processor` for which to delete the dispatches.
     */
    func deleteDispatches(_ dispatchUUIDs: [String], for processor: String)

    /**
     * Deletes all the `TealiumDispatches` from the queue and from the list of inflight for the given `processor`.
     *
     * - Parameters:
     *  - processor: The `processor` for which to delete the dispatches.
     */
    func deleteAllDispatches(for processor: String)
}
