//
//  SQLQueueRepositoryTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 23/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SQLQueueRepositoryTests: XCTestCase {
    let allProcessors = ["processor1", "processor2", "processor3"]
    let mockDatabaseProvider = MockDatabaseProvider()
    lazy var queueRepository = SQLQueueRepository(dbProvider: mockDatabaseProvider,
                                                  maxQueueSize: 100,
                                                  expiration: 1.days)

    func test_deleteQueues_removes_dispatches_of_missing_processors() {
        XCTAssertNoThrow(try queueRepository.storeDispatches([Dispatch(name: "test_event")], enqueueingFor: allProcessors))
        let dispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches.count, 1)
        XCTAssertEqual(dispatches.first?.name, "test_event")
        XCTAssertNoThrow(try queueRepository.deleteQueues(forProcessorsNotIn: ["processor2", "processor3"]))
        let dispatches2 = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches2.count, 0)
    }

    func test_storeDispatches_adds_dispatches_on_db_for_provided_processor() {
        XCTAssertNoThrow(try queueRepository.storeDispatches([Dispatch(name: "test_event")], enqueueingFor: ["processor1"]))
        let dispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches.count, 1)
        XCTAssertEqual(dispatches.first?.name, "test_event")
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: "processor2", limit: 1).count, 0)
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: "processor3", limit: 1).count, 0)
    }

    func test_storeDispatches_with_same_disaptchUUID_replaces_the_old_dispatch() {
        let dispatch = Dispatch(name: "test_event")
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch], enqueueingFor: ["processor1"]))
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: "processor1", limit: 1).count, 1)
        let future = 1.seconds.afterNow().unixTimeMilliseconds
        XCTAssertNoThrow(try queueRepository.storeDispatches([Dispatch(payload: dispatch.payload,
                                                                       id: dispatch.id,
                                                                       timestamp: future)],
                                                             enqueueingFor: ["processor2"]))
        let dispatches = queueRepository.getQueuedDispatches(for: "processor2", limit: nil)
        XCTAssertEqual(dispatches.count, 1)
        XCTAssertEqual(dispatches[0].name, dispatch.name)
        XCTAssertEqual(dispatches[0].id, dispatch.id)
        XCTAssertNotEqual(dispatches[0].timestamp, dispatch.timestamp)
        XCTAssertEqual(dispatches[0].timestamp, future)
    }

    func test_storeDispatches_with_same_disaptchUUID_deletes_queued_dispatches_for_old_processors() {
        let dispatch = Dispatch(name: "test_event")
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch], enqueueingFor: ["processor1"]))
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: "processor1", limit: 1).count, 1)
        let future = 1.seconds.afterNow().unixTimeMilliseconds
        XCTAssertNoThrow(try queueRepository.storeDispatches([Dispatch(payload: dispatch.payload,
                                                                       id: dispatch.id,
                                                                       timestamp: future)],
                                                             enqueueingFor: ["processor2"]))
        let dispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: nil)
        XCTAssertEqual(dispatches.count, 0)
    }

    func test_deleteDispatches_deletes_dispatches_for_specific_processor() {
        XCTAssertNoThrow(try queueRepository.storeDispatches([Dispatch(name: "test_event")], enqueueingFor: allProcessors))
        let dispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches.count, 1)
        XCTAssertNoThrow(try queueRepository.deleteDispatches(dispatches.map { $0.id }, for: "processor1"))
        let dispatches2 = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches2.count, 0)
    }

    func test_deleteDispatches_deletes_queue_rows() {
        let dispatch = Dispatch(name: "test_event")
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch], enqueueingFor: allProcessors))
        guard let queueRows = XCTAssertNoThrowReturn(Array(try mockDatabaseProvider.database.prepare(QueueSchema.table))) else {
            XCTFail("Failed to return Dispatch table")
            return
        }
        XCTAssertEqual(queueRows.count, 3)
        XCTAssertNoThrow(try queueRepository.deleteDispatches([dispatch.id], for: "processor1"))
        guard let queueRows2 = XCTAssertNoThrowReturn(Array(try mockDatabaseProvider.database.prepare(QueueSchema.table))) else {
            XCTFail("Failed to return Queue table")
            return
        }
        XCTAssertEqual(queueRows2.count, 2)
        XCTAssertFalse(queueRows2.contains { $0[QueueSchema.processor] == allProcessors[0] })
        XCTAssertTrue(queueRows2.contains { $0[QueueSchema.processor] == allProcessors[1] })
        XCTAssertTrue(queueRows2.contains { $0[QueueSchema.processor] == allProcessors[2] })
    }

    func test_size_returns_number_of_dispatches_stored() {
        XCTAssertNoThrow(try queueRepository.storeDispatches([Dispatch(name: "test_event")], enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 1)
    }

    func test_oldest_dispatch_is_deleted_when_an_event_is_enqueued_when_queue_is_full() {
        XCTAssertNoThrow(try queueRepository.resize(newSize: 2))
        let dispatches = [Dispatch(name: "test_event1"), Dispatch(name: "test_event2")]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 2)
        XCTAssertNoThrow(try queueRepository.storeDispatches([Dispatch(name: "test_event3")], enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 2)
        let retrievedDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 2)
        XCTAssertFalse(retrievedDispatches.contains(where: { $0.name == "test_event1" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event2" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event3" }))
    }

    func test_oldest_dispatch_by_timestamp_is_deleted_when_an_event_is_enqueued_when_queue_is_full() {
        XCTAssertNoThrow(try queueRepository.resize(newSize: 2))
        let now = Date().unixTimeMilliseconds
        let dispatches = [
            Dispatch(payload: [TealiumDataKey.event: "event1"], id: "UUID1", timestamp: now + 30),
            Dispatch(payload: [TealiumDataKey.event: "event2"], id: "UUID2", timestamp: now + 20)
        ]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 2)
        XCTAssertNoThrow(try queueRepository.storeDispatches([Dispatch(payload: [TealiumDataKey.event: "event3"],
                                                                       id: "UUID3",
                                                                       timestamp: now + 40)],
                                                     enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 2)
        let retrievedDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 2)
        XCTAssertFalse(retrievedDispatches.contains(where: { $0.name == "event2" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "event1" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "event3" }))
    }

    func test_oldest_dispatches_are_deleted_when_dispatches_are_enqueued_with_not_enough_space() {
        XCTAssertNoThrow(try queueRepository.resize(newSize: 5))
        let dispatches = [Dispatch(name: "test_event1"), Dispatch(name: "test_event2"), Dispatch(name: "test_event3")]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 3)
        let newDispatches = [Dispatch(name: "test_event4"),
                             Dispatch(name: "test_event5"),
                             Dispatch(name: "test_event6"),
                             Dispatch(name: "test_event7")]
        XCTAssertNoThrow(try queueRepository.storeDispatches(newDispatches, enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 5)
        let retrievedDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 5)
        XCTAssertFalse(retrievedDispatches.contains(where: { $0.name == "test_event1" }))
        XCTAssertFalse(retrievedDispatches.contains(where: { $0.name == "test_event2" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event3" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event4" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event5" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event6" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event7" }))
    }

    func test_storeDispatches_more_dispatches_than_queue_size_only_enqueues_the_latest_dispatches() {
        XCTAssertNoThrow(try queueRepository.resize(newSize: 2))
        let dispatches = [Dispatch(name: "test_event1"), Dispatch(name: "test_event2"), Dispatch(name: "test_event3")]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 2)
        let retrievedDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 2)
        XCTAssertFalse(retrievedDispatches.contains(where: { $0.name == "test_event1" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event2" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event3" }))
    }

    func test_getQueuedDispatches_returns_dispatches_by_timestamp() {
        let now = Date().unixTimeMilliseconds
        let dispatches = [
            Dispatch(payload: [TealiumDataKey.event: "event1"], id: "UUID1", timestamp: now),
            Dispatch(payload: [TealiumDataKey.event: "event2"], id: "UUID2", timestamp: now + 20),
            Dispatch(payload: [TealiumDataKey.event: "event3"], id: "UUID3", timestamp: now + 10)
        ]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: ["processor1"]))
        let resultDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 3)
        XCTAssertEqual(resultDispatches.count, 3)
        XCTAssertEqual(resultDispatches[0].name, "event1")
        XCTAssertEqual(resultDispatches[1].name, "event3")
        XCTAssertEqual(resultDispatches[2].name, "event2")
    }

    func test_getQueuedDispatches_excludes_expired_dispatches() {
        let now = Date().unixTimeMilliseconds
        let dispatches = [
            Dispatch(payload: [TealiumDataKey.event: "event1"], id: "UUID1", timestamp: now),
            createOldDispatch("event2", pastTimeFrame: 2.days)
        ]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: ["processor1"]))
        let resultDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 2)
        XCTAssertEqual(resultDispatches.count, 1)
        XCTAssertEqual(resultDispatches[0].name, "event1")
    }

    func test_getQueuedDispatches_excludes_explicitly_excluded_dispatches() {
        let dispatches = createDispatches(amount: 3)
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: ["processor1"]))
        let resultDispatches = queueRepository.getQueuedDispatches(for: "processor1",
                                                                   limit: nil,
                                                                   excluding: dispatches.filter { $0.name != "event1" }.map { $0.id })
        XCTAssertEqual(resultDispatches.count, 1)
        XCTAssertEqual(resultDispatches[0].name, "event1")
    }

    func test_setExpiration_deletes_newly_expired_dispatches() {
        let dispatches = [
            createOldDispatch("event1", pastTimeFrame: 2.hours),
            Dispatch(name: "event2")
        ]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: ["processor1"]))
        let resultDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: nil)
        XCTAssertEqual(resultDispatches.count, 2)
        XCTAssertNoThrow(try queueRepository.setExpiration(60.minutes))
        guard let dispatchRows = XCTAssertNoThrowReturn(Array(try mockDatabaseProvider.database.prepare(DispatchSchema.table))) else {
            XCTFail("Failed to return Dispatch table")
            return
        }
        XCTAssertEqual(dispatchRows.count, 1)
    }

    func test_setExpiration_deletes_expired_dispatches_for_old_expiration() {
        let dispatches = [
            createOldDispatch("event1", pastTimeFrame: 2.days),
            Dispatch(name: "event2")
        ]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: ["processor1"]))
        guard let dispatchRows = XCTAssertNoThrowReturn(Array(try mockDatabaseProvider.database.prepare(DispatchSchema.table))) else {
            XCTFail("Failed to return Dispatch table")
            return
        }
        XCTAssertEqual(dispatchRows.count, 2)
        XCTAssertNoThrow(try queueRepository.setExpiration(5.days))
        guard let dispatchRowsAfterSetExpiration = XCTAssertNoThrowReturn(Array(try mockDatabaseProvider.database.prepare(DispatchSchema.table))) else {
            XCTFail("Failed to return Dispatch table")
            return
        }
        XCTAssertEqual(dispatchRowsAfterSetExpiration.count, 1)

    }

    func test_resize_deletes_queued_dispatches_over_the_new_size() {
        let dispatches = createDispatches(amount: 10)
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: ["processor1"]))
        let resultDispatches = queueRepository.getQueuedDispatches(for: "processor1",
                                                                   limit: nil)
        XCTAssertEqual(resultDispatches.count, dispatches.count)
        XCTAssertNoThrow(try queueRepository.resize(newSize: 5))
        guard let dispatchRows = XCTAssertNoThrowReturn(Array(try mockDatabaseProvider.database.prepare(DispatchSchema.table))) else {
            XCTFail("Failed to return Dispatch table")
            return
        }
        XCTAssertEqual(dispatchRows.count, 5)
    }

    func test_queueSize_returns_zero_when_queue_is_empty() {
        XCTAssertEqual(queueRepository.queueSize(for: "processor1"), 0)
    }

    func test_queueSize_returns_queue_size_for_existing_and_zero_for_missing_processor() {
        let dispatch1 = Dispatch(name: "event1")
        let dispatch2 = Dispatch(name: "event2")
        let dispatch3 = Dispatch(name: "event3")
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch1, dispatch3], enqueueingFor: ["processor1"]))
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch2], enqueueingFor: ["processor2"]))
        XCTAssertEqual(queueRepository.queueSize(for: "processor1"), 2)
        XCTAssertEqual(queueRepository.queueSize(for: "processor2"), 1)
        XCTAssertEqual(queueRepository.queueSize(for: "processor3"), 0)
    }

    func test_queueSize_ignores_expired_dispatches() {
        let dispatch = Dispatch(name: "event1")
        let expiredDispatch = createOldDispatch("event3", pastTimeFrame: 2.days)
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch, expiredDispatch], enqueueingFor: ["processor1"]))
        XCTAssertEqual(queueRepository.queueSize(for: "processor1"), 1)
    }

    func test_queueSizeByProcessor_returns_empty_dictionary_when_queue_is_empty() {
        let result = queueRepository.queueSizeByProcessor()
        XCTAssertEqual(result, [:])
    }

    func test_queueSizeByProcessor_returns_dictionary_with_queue_sizes_for_existing_processors() {
        let dispatch1 = Dispatch(name: "eventA")
        let dispatch2 = Dispatch(name: "eventB")
        let dispatch3 = Dispatch(name: "eventC")
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch1, dispatch3], enqueueingFor: ["processor1"]))
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch2], enqueueingFor: ["processor2"]))
        let expected = [
            "processor1": 2,
            "processor2": 1
        ]
        XCTAssertEqual(queueRepository.queueSizeByProcessor(), expected)
    }

    func test_queueSizeByProcessor_ignores_expired_dispatches() {
        let dispatch1 = Dispatch(name: "eventA")
        let dispatch2 = Dispatch(name: "eventB")
        let expiredDispatch = createOldDispatch("eventC", pastTimeFrame: 2.days)
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch1, expiredDispatch], enqueueingFor: ["processor1"]))
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch2], enqueueingFor: ["processor2"]))
        let expected = [
            "processor1": 1,
            "processor2": 1
        ]
        XCTAssertEqual(queueRepository.queueSizeByProcessor(), expected)
    }

    private func createOldDispatch(_ name: String, pastTimeFrame: TimeFrame) -> Dispatch {
        let pastTimestamp = pastTimeFrame.beforeNow().unixTimeMilliseconds
        return Dispatch(payload: [TealiumDataKey.event: name],
                        id: UUID().uuidString,
                        timestamp: pastTimestamp)
    }
}
