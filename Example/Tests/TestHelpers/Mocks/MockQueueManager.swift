//
//  MockQueueManager.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockQueueManager: QueueManager {
    @ToAnyObservable(BasePublisher())
    var onDequeueRequest: Observable<Void>
    @ToAnyObservable(BasePublisher())
    var onDeleteRequest: Observable<([String], String)>
    override func getQueuedDispatches(for processor: String, limit: Int?) -> [Dispatch] {
        _onDequeueRequest.publish()
        return super.getQueuedDispatches(for: processor, limit: limit)
    }

    override func deleteDispatches(_ dispatchUUIDs: [String], for processor: String) {
        _onDeleteRequest.publish((dispatchUUIDs, processor))
        return super.deleteDispatches(dispatchUUIDs, for: processor)
    }
}
