//
//  MockQueueManager.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

class MockQueueManager: QueueManager {
    @Subject<Void> var onDequeueRequest
    @Subject<([String], String)> var onDeleteRequest
    @Subject<String> var onDeleteAllRequest
    @Subject<([Dispatch], [String])> var onStoreRequest
    override func dequeueDispatches(for processor: String, limit: Int?) -> [Dispatch] {
        _onDequeueRequest.publish()
        return super.dequeueDispatches(for: processor, limit: limit)
    }

    override func deleteDispatches(_ dispatchUUIDs: [String], for processor: String) {
        _onDeleteRequest.publish((dispatchUUIDs, processor))
        return super.deleteDispatches(dispatchUUIDs, for: processor)
    }

    override func storeDispatches(
        _ dispatches: [Dispatch],
        enqueueingFor processors: [String]
    ) {
        _onStoreRequest.publish((dispatches, processors))
        super.storeDispatches(dispatches, enqueueingFor: processors)
    }

    override func deleteAllDispatches(for processor: String) {
        _onDeleteAllRequest.publish(processor)
        super.deleteAllDispatches(for: processor)
    }
}
