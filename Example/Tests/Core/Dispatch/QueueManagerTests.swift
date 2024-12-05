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
    lazy var settings: DataObject = [:]
    lazy var _coreSettings = StateSubject(CoreSettings(coreDataObject: settings))
    var coreSettings: ObservableState<CoreSettings> {
        _coreSettings.toStatefulObservable()
    }
    lazy var queueRepository = SQLQueueRepository(dbProvider: dbProvider,
                                                  maxQueueSize: coreSettings.value.maxQueueSize,
                                                  expiration: coreSettings.value.queueExpiration)
    lazy var queueManager = QueueManager(processors: TealiumImpl.queueProcessors(from: modules),
                                         queueRepository: queueRepository,
                                         coreSettings: coreSettings,
                                         logger: nil)

    func test_init_removes_dispatches_queued_to_old_processors_in_db() {
        let dispatch = TealiumDispatch(name: "some_event")
        let modulesIds = modules.value.map { $0.id }
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch], enqueueingFor: modulesIds))
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: modulesIds[0], limit: nil).count, 1)
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: modulesIds[1], limit: nil).count, 1)
        _modules.value.removeFirst()
        XCTAssertEqual(queueManager.getQueuedDispatches(for: modulesIds[0], limit: nil).count, 0)
        XCTAssertEqual(queueManager.getQueuedDispatches(for: modulesIds[1], limit: nil).count, 1)
    }

    func test_modules_changes_removes_dispatches_queued_to_old_processors_in_db() {
        let dispatch = TealiumDispatch(name: "some_event")
        let modulesIds = modules.value.map { $0.id }
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch], enqueueingFor: modulesIds))
        XCTAssertEqual(queueManager.getQueuedDispatches(for: modulesIds[0], limit: nil).count, 1)
        XCTAssertEqual(queueManager.getQueuedDispatches(for: modulesIds[1], limit: nil).count, 1)
        _modules.value.removeFirst()
        XCTAssertEqual(queueManager.getQueuedDispatches(for: modulesIds[0], limit: nil).count, 0)
        XCTAssertEqual(queueManager.getQueuedDispatches(for: modulesIds[1], limit: nil).count, 1)
    }

    func test_storeDispatches_stores_a_dispatch_per_each_processor() {
        let dispatch = TealiumDispatch(name: "event_name")
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches([dispatch], enqueueingFor: modulesNames)
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 1)
        XCTAssertEqual(dispatches1[0].id, dispatch.id)
        let dispatches2 = queueManager.getQueuedDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches2.count, 1)
        XCTAssertEqual(dispatches2[0].id, dispatch.id)
    }

    func test_storeDispatches_stores_multiple_dispatches_per_each_processor() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
        let dispatches2 = queueManager.getQueuedDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches2.count, 2)
        XCTAssertEqual(dispatches2[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches2[1].id, dispatches[1].id)
    }

    func test_storeDispatches_stores_multiple_dispatches_only_for_specified_processor() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: [modulesNames[0]])
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
        let dispatches2 = queueManager.getQueuedDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches2.count, 0)
    }

    func test_storeDispatches_emits_onEnqueueEvents() {
        let enqueuedEvents = expectation(description: "EvenqueuedEvents emitted")
        queueManager.onEnqueuedDispatchesForProcessors.subscribeOnce { _ in
            enqueuedEvents.fulfill()
        }
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        waitForDefaultTimeout()
    }

    func test_storeDispatches_fails_with_duplicated_dispatch_only_inserts_one() {
        let dispatch = TealiumDispatch(name: "event_name")
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches([dispatch, dispatch], enqueueingFor: modulesNames)
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 1)
    }

    func test_getQueuedDispatches_returns_events_for_processor() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
    }

    func test_getQueuedDispatches_with_limit_returns_limited_number_of_events_for_processor() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: 2)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(dispatches1[0].id, dispatches[0].id)
        XCTAssertEqual(dispatches1[1].id, dispatches[1].id)
    }

    func test_getQueuedDispatches_puts_events_in_the_inflight_for_that_processor() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]], dispatches1.map { $0.id })
    }

    func test_getQueuedDispatches_adds_events_in_the_inflight_for_that_processor() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: 2)
        XCTAssertEqual(dispatches1.count, 2)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 2)
        let dispatches2 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: 2)
        XCTAssertEqual(dispatches2.count, 1)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 3)
    }

    func test_deleteDispatches_deletes_listed_dispatches_for_processor_from_db() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let toDelete = [dispatches[0], dispatches[1]].map { $0.id }
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 1)
        XCTAssertEqual(dispatches1[0].name, "event_name3")
    }

    func test_deleteDispatches_leaves_all_dispatches_for_other_processor_in_db() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let toDelete = [dispatches[0], dispatches[1]].map { $0.id }
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
    }

    func test_deleteDispatches_deletes_listed_dispatches_for_processor_from_inflights() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let toDelete = [dispatches[0], dispatches[1]].map { $0.id }
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 3)
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 1)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?[0], dispatches[2].id)
    }

    func test_deleteDispatches_leaves_all_dispatches_for_other_processor_in_inflights() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let toDelete = [dispatches[0], dispatches[1]].map { $0.id }
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[1]]?.count, 3)
    }

    func test_deleteAllDispatches_deletes_all_dispatches_for_processor_from_db() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        queueManager.deleteAllDispatches(for: modulesNames[0])
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 0)
    }

    func test_deleteAllDispatches_leaves_all_dispatches_for_other_processor_in_db() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        queueManager.deleteAllDispatches(for: modulesNames[0])
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
    }

    func test_deleteAllDispatches_deletes_all_dispatches_for_processor_from_inflights() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 3)
        queueManager.deleteAllDispatches(for: modulesNames[0])
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 0)
    }

    func test_deleteAllDispatches_leaves_all_dispatches_for_other_processor_in_inflights() {
        let dispatches = [TealiumDispatch(name: "event_name1"), TealiumDispatch(name: "event_name2"), TealiumDispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.getQueuedDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
        queueManager.deleteAllDispatches(for: modulesNames[0])
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[1]]?.count, 3)
    }

    func test_coreSettings_change_causes_expiration_change() {
        _ = queueManager
        XCTAssertEqual(queueRepository.expiration, TimeFrame(unit: .days, interval: 1))
        _coreSettings.publish(CoreSettings(coreDataObject: [CoreSettings.Keys.expirationSeconds: 500]))
        XCTAssertEqual(queueRepository.expiration, TimeFrame(unit: .seconds, interval: 500))
    }

    func test_coreSettings_change_causes_queueSize_change() {
        _ = queueManager
        XCTAssertEqual(queueRepository.maxQueueSize, 100)
        _coreSettings.publish(CoreSettings(coreDataObject: [CoreSettings.Keys.maxQueueSize: 20]))
        XCTAssertEqual(queueRepository.maxQueueSize, 20)
    }
}
