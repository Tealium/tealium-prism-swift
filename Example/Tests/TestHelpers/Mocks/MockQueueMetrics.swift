//
//  MockQueueMetrics.swift
//  Example_iOS
//
//  Created by Den Guzov on 04/07/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumSwift

class MockQueueMetrics: QueueMetrics {
    @StateSubject(0)
    private var size: ObservableState<Int>

    init(queueSize: Int) {
        _size.value = queueSize
    }

    func onQueueSizePendingDispatch(for processorId: String) -> TealiumSwift.Observable<Int> {
        size.asObservable()
    }

    func setQueueSize(_ size: Int) {
        _size.value = size
    }
}
