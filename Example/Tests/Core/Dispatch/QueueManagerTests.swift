//
//  QueueManagerTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 08/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class QueueManagerTests: XCTestCase {

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

    func test_init_removes_dispatches_queued_to_old_processors_in_db() {
        let dispatch = Dispatch(name: "some_event")
        let modulesIds = modules.value.map { $0.id }
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch], enqueueingFor: modulesIds))
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: modulesIds[0], limit: nil).count, 1)
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: modulesIds[1], limit: nil).count, 1)
        _modules.value.removeFirst()
        XCTAssertEqual(queueManager.dequeueDispatches(for: modulesIds[0], limit: nil).count, 0)
        XCTAssertEqual(queueManager.dequeueDispatches(for: modulesIds[1], limit: nil).count, 1)
    }

    func test_modules_changes_removes_dispatches_queued_to_old_processors() {
        let dispatch = Dispatch(name: "some_event")
        let modulesIds = modules.value.map { $0.id }
        let deletedExpectation = expectation(description: "Deleted dispatches for processors emitted")
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch], enqueueingFor: modulesIds))
        queueManager.onDeletedDispatchesForProcessors.subscribeOnce { deletedSet in
            guard deletedSet == Set(["MockDispatcher1"]) else {
                XCTFail("Unexpected deleted dispatches: \(deletedSet)")
                return
            }
            deletedExpectation.fulfill()
        }
        _modules.value.removeFirst()
        waitForDefaultTimeout()
    }

    func test_storeDispatches_stores_a_dispatch_per_each_processor() {
        let dispatch = Dispatch(name: "event_name")
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches([dispatch], enqueueingFor: modulesNames)
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 1)
        XCTAssertEqual(dispatches1[0].id, dispatch.id)
        let dispatches2 = queueManager.dequeueDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches2.count, 1)
        XCTAssertEqual(dispatches2[0].id, dispatch.id)
    }

    func test_storeDispatches_stores_multiple_dispatches_per_each_processor() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
        let dispatches2 = queueManager.dequeueDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches2.count, 2)
        XCTAssertEqual(dispatches2[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches2[1].id, dispatches[1].id)
    }

    func test_storeDispatches_stores_multiple_dispatches_only_for_specified_processor() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: [modulesNames[0]])
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
        let dispatches2 = queueManager.dequeueDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches2.count, 0)
    }

    func test_storeDispatches_emits_onEnqueueEvents() {
        let enqueuedEvents = expectation(description: "EvenqueuedEvents emitted")
        queueManager.onEnqueuedDispatchesForProcessors.subscribeOnce { _ in
            enqueuedEvents.fulfill()
        }
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        waitForDefaultTimeout()
    }

    func test_storeDispatches_fails_with_duplicated_dispatch_only_inserts_one() {
        let dispatch = Dispatch(name: "event_name")
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches([dispatch, dispatch], enqueueingFor: modulesNames)
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 1)
    }

    func test_dequeueDispatches_returns_events_for_processor() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
    }

    func test_dequeueDispatches_with_limit_returns_limited_number_of_events_for_processor() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: 2)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
    }

    func test_dequeueDispatches_puts_events_in_the_inflight_for_that_processor() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]], Set(dispatches1.map { $0.id }))
    }

    func test_dequeueDispatches_adds_events_in_the_inflight_for_that_processor() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: 2)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 2)
        let dispatches2 = queueManager.dequeueDispatches(for: modulesNames[0], limit: 2)
        XCTAssertEqual(dispatches2.count, 1)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 3)
    }

    func test_peekDispatches_returns_events_for_processor() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.peekDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
    }

    func test_peekDispatches_with_limit_returns_limited_number_of_events_for_processor() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.peekDispatches(for: modulesNames[0], limit: 2)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
    }

    func test_peekDispatches_doesnt_put_events_in_the_inflight_for_that_processor() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.peekDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertNil(queueManager.inflightEvents.value[modulesNames[0]])
    }

    func test_coreSettings_change_causes_expiration_change() {
        _ = queueManager
        XCTAssertEqual(queueRepository.expiration, TimeFrame(unit: .days, interval: 1))
        let expiration = TimeFrame(unit: .seconds, interval: 500)
        _coreSettings.publish(CoreSettings(queueExpiration: expiration))
        XCTAssertEqual(queueRepository.expiration, expiration)
    }

    func test_coreSettings_change_causes_queueSize_change() {
        _ = queueManager
        XCTAssertEqual(queueRepository.maxQueueSize, 100)
        let queueSize = 20
        _coreSettings.publish(CoreSettings(maxQueueSize: queueSize))
        XCTAssertEqual(queueRepository.maxQueueSize, queueSize)
    }

    func test_coreSettings_change_causes_onDeletedDispatchesForProcessors_emission() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let deletedExpectation = expectation(description: "Deleted dispatches emitted")
        queueManager.onDeletedDispatchesForProcessors.subscribeOnce { _ in
            deletedExpectation.fulfill()
        }
        _coreSettings.publish(CoreSettings(maxQueueSize: 2))
        waitForDefaultTimeout()
    }

    func test_onQueueSizePendingDispatch_returns_correct_count() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        let pendingCountExpectation = expectation(description: "pendingCount is 3")
        let pendingCountAfterDeleteExpectation = expectation(description: "pendingCountAfterDelete is 2")
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        queueManager.onQueueSizePendingDispatch(for: modulesNames[0]).subscribeOnce { value in
            if value == 3 {
                pendingCountExpectation.fulfill()
            }
        }
        let toDelete = [dispatches[0].id]
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        queueManager.onQueueSizePendingDispatch(for: modulesNames[0]).subscribeOnce { value in
            if value == 2 {
                pendingCountAfterDeleteExpectation.fulfill()
            }
        }
        waitForDefaultTimeout()
    }
}
