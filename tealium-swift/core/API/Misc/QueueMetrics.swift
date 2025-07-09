//
//  QueueMetrics.swift
//  tealium-swift
//
//  Created by Den Guzov on 24/06/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * A utility providing some basic insight into the number of queued events for each processor.
 */
public protocol QueueMetrics {
    /**
     * Returns an observable that will receive the current number of events queued for the given
     * `processorId`, that are not already in-flight.
     *
     * - parameter processorId: The id of the processor to get the queue size for.
     */
    func onQueueSizePendingDispatch(for processorId: String) -> Observable<Int>
}
