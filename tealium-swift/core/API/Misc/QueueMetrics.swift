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
public protocol QueueMetricsProtocol {
    /**
     * Returns an observable that will receive the current number of events queued for the given
     * `processorId`, that are not already in-flight.
     *
     * - parameter processorId: The id of the processor to get the queue size for.
     */
    func queueSizePendingDispatch(processorId: String) -> Observable<Int>
}

class QueueMetrics: QueueMetricsProtocol {
    private let queueManager: QueueManager

    init(queueManager: QueueManager) {
        self.queueManager = queueManager
    }

    func queueSizePendingDispatch(processorId: String) -> Observable<Int> {
        return queueManager.queueSizePendingDispatch(for: processorId)
    }
}
