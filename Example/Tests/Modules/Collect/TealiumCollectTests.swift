//
//  TealiumCollectTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 15/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumCollectTests: XCTestCase {
    let networkHelper = MockNetworkHelper()
    var settings = CollectSettings(moduleSettings: [:])
    lazy var collect = TealiumCollect(networkHelper: networkHelper, settings: settings)
    let stubDispatches = [
        TealiumDispatch(name: "event1", data: [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"]),
        TealiumDispatch(name: "event2", data: [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"])
    ]

    func test_send_single_dispatch() {
        let postRequestSent = expectation(description: "The POST request is sent")
        networkHelper.requests.subscribeOnce { request in
            if case let .post(url, body) = request {
                XCTAssertEqual(try? url.asUrl(), self.collect?.settings.url)
                XCTAssertEqual(body, self.stubDispatches[0].eventData)
                postRequestSent.fulfill()
            }
        }
        _ = collect?.dispatch([stubDispatches[0]], completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_send_multiple_dispatches() {
        let postRequestSent = expectation(description: "The POST request is sent")
        networkHelper.requests.subscribeOnce { request in
            if case let .post(url, body) = request {
                XCTAssertEqual(try? url.asUrl(), self.collect?.settings.batchUrl)
                XCTAssertEqual(body,
                               [
                                "shared": [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"],
                                "events": [
                                    [TealiumDataKey.event: "event1", TealiumDataKey.eventType: "event"],
                                    [TealiumDataKey.event: "event2", TealiumDataKey.eventType: "event"]
                                ]
                               ])
                postRequestSent.fulfill()
            }
        }
        _ = collect?.dispatch(stubDispatches, completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_send_single_dispatch_overrides_profile_when_provided() {
        settings = CollectSettings(moduleSettings: [CollectSettings.Keys.overrideProfile: "override"])
        let postRequestSent = expectation(description: "The POST request is sent")
        networkHelper.requests.subscribeOnce { request in
            if case let .post(_, body) = request {
                XCTAssertEqual(body.get(key: TealiumDataKey.profile), "override")
                postRequestSent.fulfill()
            }
        }
        _ = collect?.dispatch([stubDispatches[0]], completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_send_multiple_dispatches_overrides_profile_when_provided() {
        settings = CollectSettings(moduleSettings: [CollectSettings.Keys.overrideProfile: "override"])
        let postRequestSent = expectation(description: "The POST request is sent")
        networkHelper.requests.subscribeOnce { request in
            if case let .post(_, body) = request {
                XCTAssertEqual(body.getDataDictionary(key: "shared")?.get(key: TealiumDataKey.profile), "override")
                postRequestSent.fulfill()
            }
        }
        _ = collect?.dispatch(stubDispatches, completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_multiple_dispatches_with_all_different_visitorIds_are_sent_in_different_single_requests() {
        let firstVisitorSent = expectation(description: "The POST request for the first visitor is sent")
        let secondVisitorSent = expectation(description: "The POST request for the second visitor is sent")
        let subscription = networkHelper.requests.subscribe { request in
            if case let .post(_, body) = request,
               let visitorId = body.get(key: TealiumDataKey.visitorId, as: String.self) {
                if visitorId == "visitor1" {
                    firstVisitorSent.fulfill()
                } else if visitorId == "visitor2" {
                    secondVisitorSent.fulfill()
                }
            }
        }
        _ = collect?.dispatch([
            TealiumDispatch(name: "event1", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event2", data: [TealiumDataKey.visitorId: "visitor2"])
        ], completion: { _ in })
        waitForDefaultTimeout()
        subscription.dispose()
    }

    func test_multiple_dispatches_with_same_visitorIds_are_sent_in_the_same_batch() {
        let firstVisitorSent = expectation(description: "The POST request for the first visitor is sent")
        let secondVisitorSent = expectation(description: "The POST request for the second visitor is sent")
        let subscription = networkHelper.requests.subscribe { request in
            if case let .post(_, body) = request,
               let shared = body.getDataDictionary(key: "shared"),
               let visitorId = shared.get(key: TealiumDataKey.visitorId, as: String.self) {
                if visitorId == "visitor1" {
                    firstVisitorSent.fulfill()
                } else if visitorId == "visitor2" {
                    secondVisitorSent.fulfill()
                }
            }
        }
        _ = collect?.dispatch([
            TealiumDispatch(name: "event1", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event2", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event3", data: [TealiumDataKey.visitorId: "visitor2"]),
            TealiumDispatch(name: "event4", data: [TealiumDataKey.visitorId: "visitor2"])
        ], completion: { _ in })
        waitForDefaultTimeout()
        subscription.dispose()
    }

    func test_multiple_dispatches_with_same_visitorIds_only_complete_with_the_batched_events() {
        let firstVisitorSent = expectation(description: "The POST request for the first visitor is sent")
        let secondVisitorSent = expectation(description: "The POST request for the second visitor is sent")
        _ = collect?.dispatch([
            TealiumDispatch(name: "event1", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event2", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event3", data: [TealiumDataKey.visitorId: "visitor2"])
        ], completion: { events in
            let visitorIdsArray = events.map { $0.eventData.get(key: TealiumDataKey.visitorId) ?? "" }
            XCTAssertEqual(Set(visitorIdsArray).count, 1, "All visitorIds should be the same in this batch")
            if visitorIdsArray[0] == "visitor1" {
                firstVisitorSent.fulfill()
            } else if visitorIdsArray[0] == "visitor2" {
                secondVisitorSent.fulfill()
            }
        })
        waitForDefaultTimeout()
    }

    func test_disposed_dispatch_are_not_completed() {
        let postRequestCancelled = expectation(description: "The POST request is cancelled")
        networkHelper.delay = 0
        let subscription = collect?.dispatch([stubDispatches[0]], completion: { dispatches in
            XCTAssertEqual(dispatches.count, 0)
            postRequestCancelled.fulfill()
        })
        subscription?.dispose()
        waitForDefaultTimeout()
    }

    func test_collect_is_not_initialized_when_settings_are_nil() {
        settings = nil
        XCTAssertNil(collect)
    }

    func test_updateSettings_changes_collectSettings() {
        let updatedCollect = collect?.updateSettings(["url": "customUrl"])
        XCTAssertNotNil(updatedCollect)
        XCTAssertEqual(updatedCollect?.settings.url.absoluteString, "customUrl")
    }

    func test_updateSettings_with_invalid_urls_returns_nil() {
        let updatedCollect = collect?.updateSettings(["url": ""])
        XCTAssertNil(updatedCollect)
    }
}
