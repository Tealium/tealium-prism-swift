//
//  MockQueueMetrics.swift
//  Example_iOS
//
//  Created by Den Guzov on 04/07/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumPrism

class MockQueueMetrics: QueueMetrics {
    @StateSubject(0)
    private var size: ObservableState<Int>
    /// The sizes requested so far per processor, which follow `setQueueSize(_:)` unless set specifically with `setQueueSize(_:for:)`.
    private var processorSizes = [String: StateSubject<Int>]()

    init(queueSize: Int) {
        _size.value = queueSize
    }

    func onQueueSizePendingDispatch(for processorId: String) -> Observable<Int> {
        processorSize(for: processorId).asObservable()
    }

    func setQueueSize(_ size: Int) {
        _size.value = size
        processorSizes.values.forEach { $0.value = size }
    }

    func setQueueSize(_ size: Int, for processorId: String) {
        processorSize(for: processorId).value = size
    }

    private func processorSize(for processorId: String) -> StateSubject<Int> {
        if let processorSize = processorSizes[processorId] {
            return processorSize
        }
        let processorSize = StateSubject(size.value)
        processorSizes[processorId] = processorSize
        return processorSize
    }
}
