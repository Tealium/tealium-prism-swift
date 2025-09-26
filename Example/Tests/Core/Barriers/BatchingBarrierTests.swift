//
//  BatchingBarrierTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/07/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class BatchingBarrierTests: XCTestCase {
    let queueMetrics = MockQueueMetrics(queueSize: 1)
    @StateSubject<[Dispatcher]>([MockDispatcher1(), MockDispatcher2()]) // dispatch limits: 1, 3
    var dispatchers: ObservableState<[Dispatcher]>
    var testBatchSize: Int = 1
    lazy var barrier: BatchingBarrier = .init(queueMetrics: queueMetrics, dispatchers: dispatchers, configuration: [
        BatchingSettings.Keys.batchSize: testBatchSize
    ])

    func test_onState_prefers_configured_batchSize_when_less_than_dispatchLimit() {
        let barrierOpen = expectation(description: "Barrier should be open")
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onState_uses_dispatchLimit_when_configured_batchSize_greater_than_dispatchLimit() {
        setBatchSize(5)
        let barrierOpen = expectation(description: "Barrier should be open")
        barrier.onState(for: MockDispatcher1.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onState_uses_dispatchLimit_when_batchSize_not_configured() {
        setBatchSize(nil)
        queueMetrics.setQueueSize(3)
        let barrierOpen = expectation(description: "Barrier should be open")
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onState_uses_batch_size_1_when_configured_batchSize_is_negative_or_zero() {
        let barrierOpen = expectation(description: "Barrier should be open")
        barrierOpen.expectedFulfillmentCount = 2
        setBatchSize(0)
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        setBatchSize(-10)
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onState_uses_batch_size_1_when_configured_batchSize_and_dispatch_limit_are_negative() {
        let barrierOpen = expectation(description: "Barrier should be open")
        setBatchSize(-10)
        _dispatchers.value = [MockDispatcher2(dispatchLimit: -5)]
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        let barrierClosed = expectation(description: "Barrier should be closed")
        queueMetrics.setQueueSize(0)
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            barrierClosed.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onState_returns_open_when_queue_size_is_greater_than_batch_size() {
        queueMetrics.setQueueSize(2)
        let barrierOpen = expectation(description: "Barrier should be open")
        barrier.onState(for: MockDispatcher1.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onState_returns_closed_when_queue_size_is_less_than_batch_size() {
        queueMetrics.setQueueSize(0)
        let barrierClosed = expectation(description: "Barrier should be closed")
        barrier.onState(for: MockDispatcher1.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            barrierClosed.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onState_opens_when_queue_size_becomes_equal_to_batch_size() {
        let barrierClosed = expectation(description: "Barrier should be closed")
        queueMetrics.setQueueSize(0)
        barrier.onState(for: MockDispatcher1.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            barrierClosed.fulfill()
        }
        let barrierOpen = expectation(description: "Barrier should be open")
        queueMetrics.setQueueSize(1)
        barrier.onState(for: MockDispatcher1.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onState_closes_when_queue_size_becomes_less_than_batch_size() {
        let barrierOpen = expectation(description: "Barrier should be open")
        barrier.onState(for: MockDispatcher1.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        let barrierClosed = expectation(description: "Barrier should be closed")
        queueMetrics.setQueueSize(0)
        barrier.onState(for: MockDispatcher1.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            barrierClosed.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onState_opens_when_batch_size_becomes_less_than_or_equal_to_queue_size() {
        let barrierClosed = expectation(description: "Barrier should be closed")
        setBatchSize(3)
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            barrierClosed.fulfill()
        }
        let barrierOpen = expectation(description: "Barrier should be open")
        setBatchSize(1)
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_updateConfiguration_sets_batch_size_to_new_value() {
        barrier.updateConfiguration([
            BatchingSettings.Keys.batchSize: 2
        ])
        let barrierClosed = expectation(description: "Barrier should be closed")
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            barrierClosed.fulfill()
        }
        queueMetrics.setQueueSize(2)
        let barrierOpen = expectation(description: "Barrier should be open")
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_updateConfiguration_sets_batch_size_to_nil_when_omitted() {
        queueMetrics.setQueueSize(2)
        setBatchSize(2)
        let barrierOpen = expectation(description: "Barrier should be open")
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        barrier.updateConfiguration([:])
        let barrierClosed = expectation(description: "Barrier should be closed")
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            barrierClosed.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_dispatchers_opens_barrier_when_updated_with_less_dispatchLimit() {
        setBatchSize(nil)
        let barrierClosed = expectation(description: "Barrier should be closed")
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            barrierClosed.fulfill()
        }
        _dispatchers.value = [MockDispatcher2(dispatchLimit: 1)]
        let barrierOpen = expectation(description: "Barrier should be open")
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_dispatchers_closes_barrier_when_updated_with_greater_dispatchLimit() {
        setBatchSize(nil)
        queueMetrics.setQueueSize(3)
        let barrierOpen = expectation(description: "Barrier should be open")
        barrier.onState(for: MockDispatcher2.moduleType).subscribeOnce { state in
            XCTAssertEqual(state, .open)
            barrierOpen.fulfill()
        }
        _dispatchers.value = [MockDispatcher2(moduleId: "id", dispatchLimit: 5)]
        let barrierClosed = expectation(description: "Barrier should be closed")
        barrier.onState(for: "id").subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            barrierClosed.fulfill()
        }
        waitForDefaultTimeout()
    }

    private func setBatchSize(_ size: Int?) {
        guard let size else {
            barrier.updateConfiguration([:])
            return
        }
        barrier.updateConfiguration([
            BatchingSettings.Keys.batchSize: size
        ])
    }
}
