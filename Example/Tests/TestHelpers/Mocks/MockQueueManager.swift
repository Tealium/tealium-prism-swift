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
    @ToAnyObservable(TealiumPublisher())
    var onDequeueRequest: TealiumObservable<Void>
    override func getQueuedDispatches(for processor: String, limit: Int?) -> [TealiumDispatch] {
        _onDequeueRequest.publish()
        return super.getQueuedDispatches(for: processor, limit: limit)
    }
}
