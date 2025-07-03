//
//  QueueMetricsTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 08/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class QueueMetricsTests: XCTestCase {

    let disposer = AutomaticDisposer()
    @StateSubject([MockDispatcher1(), MockDispatcher2()])
    var modules: ObservableState<[TealiumModule]>
    let dbProvider = MockDatabaseProvider()
    @StateSubject(CoreSettings())
    var coreSettings
    lazy var queueRepository = SQLQueueRepository(dbProvider: dbProvider,
                                                  maxQueueSize: coreSettings.value.maxQueueSize,
                                                  expiration: coreSettings.value.queueExpiration)
    lazy var queueManager = QueueManager(processors: TealiumImpl.queueProcessors(from: modules, addingConsent: true),
                                         queueRepository: queueRepository,
                                         coreSettings: coreSettings,
                                         logger: nil)
    lazy var queueMetrics = QueueMetrics(queueManager: queueManager)

    override func setUp() {
        // store one dispatch for MockDispatcher1 by default
        queueManager.storeDispatches([Dispatch(name: "event_name1")], enqueueingFor: ["MockDispatcher1"])
    }

    func test_queueSizePendingDispatch_emits_initial_value_for_given_processor() {
        XCTAssertObservedValueEqual(queueMetrics.queueSizePendingDispatch(processorId: "MockDispatcher1"), 1)
    }

    func test_queueSizePendingDispatch_emits_correct_values_for_different_processors() {
        queueManager.storeDispatches([Dispatch(name: "event_name1"), Dispatch(name: "event_name2")], enqueueingFor: ["MockDispatcher2"])
        XCTAssertObservedValueEqual(queueMetrics.queueSizePendingDispatch(processorId: "MockDispatcher1"), 1)
        XCTAssertObservedValueEqual(queueMetrics.queueSizePendingDispatch(processorId: "MockDispatcher2"), 2)
    }

    func test_queueSizePendingDispatch_does_not_emit_if_queue_size_unchanged() {
        let emitted = expectation(description: "Should not emit more than once")
        queueMetrics.queueSizePendingDispatch(processorId: "MockDispatcher1").subscribe { _ in
            emitted.fulfill()
        }.addTo(disposer)
        queueManager.deleteDispatches(["missing_dispatch"], for: "MockDispatcher1")
        waitForDefaultTimeout()
    }

    
}
