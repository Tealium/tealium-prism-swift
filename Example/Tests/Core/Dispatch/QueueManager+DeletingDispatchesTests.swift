//
//  QueueManager+DeletingDispatchesTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 08/05/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class QueueManagerDeletingDispatchesTests: XCTestCase {

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

    func test_deleteDispatches_deletes_listed_dispatches_for_processor_from_db() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let toDelete = [dispatches[0], dispatches[1]].map { $0.id }
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 1)
        XCTAssertEqual(dispatches1[0].name, "event_name3")
    }

    func test_deleteDispatches_leaves_all_dispatches_for_other_processor_in_db() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let toDelete = [dispatches[0], dispatches[1]].map { $0.id }
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
    }

    func test_deleteDispatches_deletes_listed_dispatches_for_processor_from_inflights() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let toDelete = [dispatches[0], dispatches[1]].map { $0.id }
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 3)
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 1)
        XCTAssertTrueOptional(queueManager.inflightEvents.value[modulesNames[0]]?.contains(dispatches[2].id))
    }

    func test_deleteDispatches_leaves_all_dispatches_for_other_processor_in_inflights() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let toDelete = [dispatches[0], dispatches[1]].map { $0.id }
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[1]]?.count, 3)
    }

    func test_deleteAllDispatches_deletes_all_dispatches_for_processor_from_db() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        queueManager.deleteAllDispatches(for: modulesNames[0])
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 0)
    }

    func test_deleteAllDispatches_leaves_all_dispatches_for_other_processor_in_db() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        queueManager.deleteAllDispatches(for: modulesNames[0])
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
    }

    func test_deleteAllDispatches_deletes_all_dispatches_for_processor_from_inflights() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[0], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[0]]?.count, 3)
        queueManager.deleteAllDispatches(for: modulesNames[0])
        XCTAssertNil(queueManager.inflightEvents.value[modulesNames[0]])
    }

    func test_deleteAllDispatches_leaves_all_dispatches_for_other_processor_in_inflights() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let dispatches1 = queueManager.dequeueDispatches(for: modulesNames[1], limit: nil)
        XCTAssertEqual(dispatches1.count, 3)
        queueManager.deleteAllDispatches(for: modulesNames[0])
        XCTAssertEqual(queueManager.inflightEvents.value[modulesNames[1]]?.count, 3)
    }

    func test_deleteAllDispatches_causes_onDeletedDispatchesForProcessors_to_emit_processor_ids() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let deletedExpectation = expectation(description: "Deleted dispatches for processors emitted")
        queueManager.onDeletedDispatchesForProcessors.subscribeOnce { deletedSet in
            guard deletedSet == Set([modulesNames[0]]) else {
                XCTFail("Unexpected deleted dispatches: \(deletedSet)")
                return
            }
            deletedExpectation.fulfill()
        }
        queueManager.deleteAllDispatches(for: modulesNames[0])
        waitForDefaultTimeout()
    }

    func test_deleteDispatches_causes_onDeletedDispatchesForProcessors_to_emit_processor_ids() {
        let dispatches = [Dispatch(name: "event_name1"), Dispatch(name: "event_name2"), Dispatch(name: "event_name3")]
        let modulesNames = modules.value.map { $0.id }
        queueManager.storeDispatches(dispatches, enqueueingFor: modulesNames)
        let toDelete = [dispatches[0], dispatches[1]].map { $0.id }
        let deletedExpectation = expectation(description: "Deleted dispatches for processors emitted")
        queueManager.onDeletedDispatchesForProcessors.subscribeOnce { deletedSet in
            guard deletedSet == Set([modulesNames[0]]) else {
                XCTFail("Unexpected deleted dispatches: \(deletedSet)")
                return
            }
            deletedExpectation.fulfill()
        }
        queueManager.deleteDispatches(toDelete, for: modulesNames[0])
        waitForDefaultTimeout()
    }
}
