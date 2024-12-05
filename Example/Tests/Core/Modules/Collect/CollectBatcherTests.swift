//
//  CollectBatcherTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 14/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class CollectBatcherTests: XCTestCase {
    let batcher = CollectBatcher()
    let stubEvent: DataObject = [
        TealiumDataKey.account: "account",
        TealiumDataKey.profile: "profile",
        TealiumDataKey.visitorId: "visitorId",
        "key": "value"
    ]

    func test_extractSharedKeys_returns_the_shared_keys() {
        let shared = batcher.extractSharedKeys(from: stubEvent, profileOverride: nil)
        XCTAssertEqual(shared, [
            TealiumDataKey.account: "account",
            TealiumDataKey.profile: "profile",
            TealiumDataKey.visitorId: "visitorId"
        ])
    }

    func test_extractSharedKeys_removes_non_shared_keys() {
        let shared = batcher.extractSharedKeys(from: stubEvent, profileOverride: nil)
        XCTAssertNil(shared.getDataItem(key: "key"))
    }

    func test_compressDispatches_returns_nil_for_empty_dispatches() {
        XCTAssertNil(batcher.compressDispatches([], profileOverride: nil))
    }

    func test_compressDispatches_puts_sharedKeys_in_shared_property() {
        let dispatches = [
            TealiumDispatch(name: "event1", data: stubEvent),
            TealiumDispatch(name: "event2", data: stubEvent)
        ]
        guard let result = batcher.compressDispatches(dispatches, profileOverride: nil) else {
            XCTFail("Compress dispatches should return a result")
            return
        }
        guard let shared = result.getDataItem(key: "shared")?.toDataInput() as? [String: Any] else {
            XCTFail("Shared not returned from compress dispatches")
            return
        }
        XCTAssertEqual(shared, [
            TealiumDataKey.account: "account",
            TealiumDataKey.profile: "profile",
            TealiumDataKey.visitorId: "visitorId"
        ])
    }

    func test_compressDispatches_puts_events_array_in_events_property() {
        let dispatches = [
            TealiumDispatch(name: "event1", data: stubEvent),
            TealiumDispatch(name: "event2", data: stubEvent)
        ]
        guard let result = batcher.compressDispatches(dispatches, profileOverride: nil) else {
            XCTFail("Compress dispatches should return a result")
            return
        }
        guard let events = result.getDataItem(key: "events")?.toDataInput() as? [[String: Any]] else {
            XCTFail("Shared not returned from compress dispatches")
            return
        }
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0][TealiumDataKey.event] as? String, "event1")
        XCTAssertEqual(events[1][TealiumDataKey.event] as? String, "event2")
    }

    func test_compressDispatches_returns_events_without_shared_keys() {
        let dispatches = [
            TealiumDispatch(name: "event1", data: stubEvent),
            TealiumDispatch(name: "event2", data: stubEvent)
        ]
        guard let result = batcher.compressDispatches(dispatches, profileOverride: nil) else {
            XCTFail("Compress dispatches should return a result")
            return
        }
        guard let events = result.getDataItem(key: "events")?.toDataInput() as? [[String: Any]], events.count > 0 else {
            XCTFail("Shared not returned from compress dispatches")
            return
        }
        for event in events {
            XCTAssertNil(event[TealiumDataKey.account])
            XCTAssertNil(event[TealiumDataKey.profile])
            XCTAssertNil(event[TealiumDataKey.visitorId])
        }
    }

    func test_compressDispatches_overrides_profile_when_provided() {
        let dispatches = [
            TealiumDispatch(name: "event1", data: stubEvent),
            TealiumDispatch(name: "event2", data: stubEvent)
        ]
        guard let result = batcher.compressDispatches(dispatches, profileOverride: "override") else {
            XCTFail("Compress dispatches should return a result")
            return
        }
        guard let shared = result.getDataItem(key: "shared")?.toDataInput() as? [String: Any] else {
            XCTFail("Shared not returned from compress dispatches")
            return
        }
        XCTAssertEqual(shared[TealiumDataKey.profile] as? String, "override")
    }

    func test_splitDispatchesByVisitorId_returns_batches_with_the_same_id() {
        let events = [
            stubEvent + [TealiumDataKey.visitorId: "visitorId1"],
            stubEvent + [TealiumDataKey.visitorId: "visitorId2"],
            stubEvent + [TealiumDataKey.visitorId: "visitorId2"],
            [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"]
        ]
        let result = batcher.splitDispatchesByVisitorId(events.map { TealiumDispatch(name: "some_event", data: $0) })
        let dataItemsMatrix = result.map { $0.map { $0.eventData.getDataItem(key: TealiumDataKey.visitorId) } }
        for dataItems in dataItemsMatrix {
            let nonOptionalVisitorIdsArray = dataItems.map { $0?.get() ?? "" }
            XCTAssertEqual(Set(nonOptionalVisitorIdsArray).count, 1, "All visitorIds should be the same in each batch")
        }
    }

    func test_splitDispatchesByVisitorId_returns_batches_for_all_visitor_ids() {
        let events = [
            stubEvent + [TealiumDataKey.visitorId: "visitorId1"],
            stubEvent + [TealiumDataKey.visitorId: "visitorId2"],
            stubEvent + [TealiumDataKey.visitorId: "visitorId2"],
            [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"]
        ]
        let result = batcher.splitDispatchesByVisitorId(events.map { TealiumDispatch(name: "some_event", data: $0) })
        let visitorIdMatrix = result.map { $0.map { $0.eventData.get(key: TealiumDataKey.visitorId, as: String.self) } }
        for event in events {
            let visitorId = event.get(key: TealiumDataKey.visitorId, as: String.self)
            XCTAssertTrue(visitorIdMatrix.contains(where: { $0.first == visitorId }), "All visitor IDs should've been split in different batches")
        }
    }

    func test_splitDispatchesByVisitorId_returns_batches_that_contain_all_the_events() {
        let events = [
            stubEvent + [TealiumDataKey.visitorId: "visitorId1", "event": "1"],
            stubEvent + [TealiumDataKey.visitorId: "visitorId2", "event": "2"],
            stubEvent + [TealiumDataKey.visitorId: "visitorId2", "event": "3"],
            [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile", "event": "4"]
        ]
        let result = batcher.splitDispatchesByVisitorId(events.map { TealiumDispatch(name: "some_event", data: $0) })
        let eventsMatrix = result.map { $0.map { $0.eventData.get(key: "event", as: String.self) } }
        for event in events {
            let eventId = event.get(key: "event", as: String.self)
            XCTAssertTrue(eventsMatrix.contains(where: { $0.contains(eventId) }), "All events should be contained in the batch")
        }
    }

    func test_splitDispatchesByVisitorId_returns_batches_that_do_not_duplicate_events() {
        let events = [
            stubEvent + [TealiumDataKey.visitorId: "visitorId1", "event": "1"],
            stubEvent + [TealiumDataKey.visitorId: "visitorId2", "event": "2"],
            stubEvent + [TealiumDataKey.visitorId: "visitorId2", "event": "3"],
            [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile", "event": "4"]
        ]
        let result = batcher.splitDispatchesByVisitorId(events.map { TealiumDispatch(name: "some_event", data: $0) })
        let eventsMatrix = result.map { $0.map { $0.eventData.get(key: "event", as: String.self) } }
        for event in events {
            let eventId = event.get(key: "event", as: String.self)
            var count = 0
            for array in eventsMatrix {
                for singleResult in array where singleResult == eventId {
                    count += 1
                }
            }
            XCTAssertEqual(count, 1, "All events should be contained only once in the batch")
        }
    }

    func test_applyProfileOverride_with_override_changes_the_profile_data() {
        var event: DataObject = [TealiumDataKey.profile: "profile"]
        batcher.applyProfileOverride("override", to: &event)
        XCTAssertEqual(event.get(key: TealiumDataKey.profile), "override")
    }

    func test_applyProfileOverride_with_nil_does_nothing() {
        var event: DataObject = [TealiumDataKey.profile: "profile"]
        batcher.applyProfileOverride(nil, to: &event)
        XCTAssertEqual(event.get(key: TealiumDataKey.profile), "profile")
    }
}
