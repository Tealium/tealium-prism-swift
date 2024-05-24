//
//  SQLQueueRepositoryTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 23/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class SQLQueueRepositoryTests: XCTestCase {
    let allProcessors = ["processor1", "processor2", "processor3"]
    let mockDatabaseProvider = MockDatabaseProvider()
    lazy var queueRepository = SQLQueueRepository(dbProvider: mockDatabaseProvider,
                                                  maxQueueSize: 100,
                                                  expiration: TimeFrame(unit: .days, interval: 1))

    func test_deleteQueues_removes_dispatches_of_missing_processors() {
        XCTAssertNoThrow(try queueRepository.storeDispatches([TealiumDispatch(name: "test_event")], enqueueingFor: allProcessors))
        let dispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches.count, 1)
        XCTAssertEqual(dispatches.first?.name, "test_event")
        XCTAssertNoThrow(try queueRepository.deleteQueues(forProcessorsNotIn: ["processor2", "processor3"]))
        let dispatches2 = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches2.count, 0)
    }

    func test_storeDispatches_adds_dispatches_on_db_for_provided_processor() {
        XCTAssertNoThrow(try queueRepository.storeDispatches([TealiumDispatch(name: "test_event")], enqueueingFor: ["processor1"]))
        let dispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches.count, 1)
        XCTAssertEqual(dispatches.first?.name, "test_event")
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: "processor2", limit: 1).count, 0)
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: "processor3", limit: 1).count, 0)
    }

    func test_storeDispatches_with_same_disaptchUUID_replaces_the_old_dispatch() {
        let dispatch = TealiumDispatch(name: "test_event")
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch], enqueueingFor: ["processor1"]))
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: "processor1", limit: 1).count, 1)
        let future = Date().unixTimeMillisecondsInt + 1000
        XCTAssertNoThrow(try queueRepository.storeDispatches([TealiumDispatch(eventData: dispatch.eventData,
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
        let dispatch = TealiumDispatch(name: "test_event")
        XCTAssertNoThrow(try queueRepository.storeDispatches([dispatch], enqueueingFor: ["processor1"]))
        XCTAssertEqual(queueRepository.getQueuedDispatches(for: "processor1", limit: 1).count, 1)
        let future = Date().unixTimeMillisecondsInt + 1000
        XCTAssertNoThrow(try queueRepository.storeDispatches([TealiumDispatch(eventData: dispatch.eventData,
                                                                              id: dispatch.id,
                                                                              timestamp: future)],
                                                             enqueueingFor: ["processor2"]))
        let dispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: nil)
        XCTAssertEqual(dispatches.count, 0)
    }

    func test_deleteDispatches_deletes_dispatches_for_specific_processor() {
        XCTAssertNoThrow(try queueRepository.storeDispatches([TealiumDispatch(name: "test_event")], enqueueingFor: allProcessors))
        let dispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches.count, 1)
        XCTAssertNoThrow(try queueRepository.deleteDispatches(dispatches.map { $0.id }, for: "processor1"))
        let dispatches2 = queueRepository.getQueuedDispatches(for: "processor1", limit: 1)
        XCTAssertEqual(dispatches2.count, 0)
    }

    func test_deleteDispatches_deletes_queue_rows() {
        let dispatch = TealiumDispatch(name: "test_event")
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
        XCTAssertNoThrow(try queueRepository.storeDispatches([TealiumDispatch(name: "test_event")], enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 1)
    }

    func test_oldest_dispatch_is_deleted_when_an_event_is_enqueued_when_queue_is_full() {
        XCTAssertNoThrow(try queueRepository.resize(newSize: 2))
        let dispatches = [TealiumDispatch(name: "test_event1"), TealiumDispatch(name: "test_event2")]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 2)
        XCTAssertNoThrow(try queueRepository.storeDispatches([TealiumDispatch(name: "test_event3")], enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 2)
        let retrievedDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 2)
        XCTAssertFalse(retrievedDispatches.contains(where: { $0.name == "test_event1" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event2" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event3" }))
    }

    func test_oldest_dispatch_by_timestamp_is_deleted_when_an_event_is_enqueued_when_queue_is_full() {
        XCTAssertNoThrow(try queueRepository.resize(newSize: 2))
        let now = Date().unixTimeMillisecondsInt
        let dispatches = [
            TealiumDispatch(eventData: [TealiumDataKey.event: "event1"], id: "UUID1", timestamp: now + 30),
            TealiumDispatch(eventData: [TealiumDataKey.event: "event2"], id: "UUID2", timestamp: now + 20)
        ]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 2)
        XCTAssertNoThrow(try queueRepository.storeDispatches([TealiumDispatch(eventData: [TealiumDataKey.event: "event3"],
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
        let dispatches = [TealiumDispatch(name: "test_event1"), TealiumDispatch(name: "test_event2"), TealiumDispatch(name: "test_event3")]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 3)
        let newDispatches = [TealiumDispatch(name: "test_event4"),
                             TealiumDispatch(name: "test_event5"),
                             TealiumDispatch(name: "test_event6"),
                             TealiumDispatch(name: "test_event7")]
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
        let dispatches = [TealiumDispatch(name: "test_event1"), TealiumDispatch(name: "test_event2"), TealiumDispatch(name: "test_event3")]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: allProcessors))
        XCTAssertEqual(queueRepository.size, 2)
        let retrievedDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 2)
        XCTAssertFalse(retrievedDispatches.contains(where: { $0.name == "test_event1" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event2" }))
        XCTAssertTrue(retrievedDispatches.contains(where: { $0.name == "test_event3" }))
    }

    func test_getQueuedDispatches_returns_dispatches_by_timestamp() {
        let now = Date().unixTimeMillisecondsInt
        let dispatches = [
            TealiumDispatch(eventData: [TealiumDataKey.event: "event1"], id: "UUID1", timestamp: now),
            TealiumDispatch(eventData: [TealiumDataKey.event: "event2"], id: "UUID2", timestamp: now + 20),
            TealiumDispatch(eventData: [TealiumDataKey.event: "event3"], id: "UUID3", timestamp: now + 10)
        ]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: ["processor1"]))
        let resultDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: 3)
        XCTAssertEqual(resultDispatches.count, 3)
        XCTAssertEqual(resultDispatches[0].name, "event1")
        XCTAssertEqual(resultDispatches[1].name, "event3")
        XCTAssertEqual(resultDispatches[2].name, "event2")
    }

    func test_getQueuedDispatches_excludes_expired_dispatches() {
        guard let twoDaysAgo = Date().addMinutes(-2880)?.unixTimeMillisecondsInt else {
            return
        }
        let now = Date().unixTimeMillisecondsInt
        let dispatches = [
            TealiumDispatch(eventData: [TealiumDataKey.event: "event1"], id: "UUID1", timestamp: now),
            TealiumDispatch(eventData: [TealiumDataKey.event: "event2"], id: "UUID2", timestamp: twoDaysAgo)
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
        guard let twoHoursAgo = Date().addMinutes(-120)?.unixTimeMillisecondsInt else {
            return
        }
        let dispatches = [
            TealiumDispatch(eventData: [TealiumDataKey.event: "event1"], id: "UUID", timestamp: twoHoursAgo),
            TealiumDispatch(name: "event2")
        ]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: ["processor1"]))
        let resultDispatches = queueRepository.getQueuedDispatches(for: "processor1", limit: nil)
        XCTAssertEqual(resultDispatches.count, 2)
        XCTAssertNoThrow(try queueRepository.setExpiration(TimeFrame(unit: .minutes, interval: 60)))
        guard let dispatchRows = XCTAssertNoThrowReturn(Array(try mockDatabaseProvider.database.prepare(DispatchSchema.table))) else {
            XCTFail("Failed to return Dispatch table")
            return
        }
        XCTAssertEqual(dispatchRows.count, 1)
    }

    func test_setExpiration_deletes_expired_dispatches_for_old_expiration() {
        guard let twoDaysAgo = Date().addMinutes(-2880)?.unixTimeMillisecondsInt else {
            return
        }
        let dispatches = [
            TealiumDispatch(eventData: [TealiumDataKey.event: "event1"], id: "UUID", timestamp: twoDaysAgo),
            TealiumDispatch(name: "event2")
        ]
        XCTAssertNoThrow(try queueRepository.storeDispatches(dispatches, enqueueingFor: ["processor1"]))
        guard let dispatchRows = XCTAssertNoThrowReturn(Array(try mockDatabaseProvider.database.prepare(DispatchSchema.table))) else {
            XCTFail("Failed to return Dispatch table")
            return
        }
        XCTAssertEqual(dispatchRows.count, 2)
        XCTAssertNoThrow(try queueRepository.setExpiration(TimeFrame(unit: .days, interval: 5)))
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

    private func createDispatches(amount: Int) -> [TealiumDispatch] {
        (1...amount).map { count in
            TealiumDispatch(name: "event\(count)")
        }
    }
}
