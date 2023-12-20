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
    var settings = TealiumCollectSettings(moduleSettings: [:])
    lazy var collect = TealiumCollect(networkHelper: networkHelper, settings: settings)
    let stubDispatches = [
        TealiumDispatch(name: "event1", data: [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"]),
        TealiumDispatch(name: "event2", data: [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"])
    ]

    func test_send_single_dispatch() {
        let postRequestSent = expectation(description: "The POST request is sent")
        networkHelper.requests.subscribeOnce { request in
            if case let .post(url, body) = request {
                XCTAssertEqual(try? url.asUrl(), self.collect.settings.url)
                XCTAssertEqual(body as NSDictionary, self.stubDispatches[0].eventData as NSDictionary)
                postRequestSent.fulfill()
            }
        }
        _ = collect.dispatch([stubDispatches[0]], completion: { _ in })
        waitForExpectations(timeout: 1.0)
    }

    func test_send_multiple_dispatches() {
        let postRequestSent = expectation(description: "The POST request is sent")
        networkHelper.requests.subscribeOnce { request in
            if case let .post(url, body) = request {
                XCTAssertEqual(try? url.asUrl(), self.collect.settings.batchUrl)
                XCTAssertEqual(body as NSDictionary,
                               [
                                "shared": [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"],
                                "events": [
                                    [TealiumDataKey.event: "event1", TealiumDataKey.eventType: "event"],
                                    [TealiumDataKey.event: "event2", TealiumDataKey.eventType: "event"]
                                ]
                               ] as NSDictionary)
                postRequestSent.fulfill()
            }
        }
        _ = collect.dispatch(stubDispatches, completion: { _ in })
        waitForExpectations(timeout: 1.0)
    }

    func test_send_single_dispatch_overrides_profile_when_provided() {
        settings = TealiumCollectSettings(moduleSettings: [TealiumCollectSettings.Keys.overrideProfile: "override"])
        let postRequestSent = expectation(description: "The POST request is sent")
        networkHelper.requests.subscribeOnce { request in
            if case let .post(_, body) = request {
                XCTAssertEqual(body[TealiumDataKey.profile] as? String, "override")
                postRequestSent.fulfill()
            }
        }
        _ = collect.dispatch([stubDispatches[0]], completion: { _ in })
        waitForExpectations(timeout: 1.0)
    }

    func test_send_multiple_dispatches_overrides_profile_when_provided() {
        settings = TealiumCollectSettings(moduleSettings: [TealiumCollectSettings.Keys.overrideProfile: "override"])
        let postRequestSent = expectation(description: "The POST request is sent")
        networkHelper.requests.subscribeOnce { request in
            if case let .post(_, body) = request {
                XCTAssertEqual((body["shared"] as? [String: Any])?[TealiumDataKey.profile] as? String, "override")
                postRequestSent.fulfill()
            }
        }
        _ = collect.dispatch(stubDispatches, completion: { _ in })
        waitForExpectations(timeout: 1.0)
    }

    func test_multiple_dispatches_with_all_different_visitorIds_are_sent_in_different_single_requests() {
        let firstVisitorSent = expectation(description: "The POST request for the first visitor is sent")
        let secondVisitorSent = expectation(description: "The POST request for the second visitor is sent")
        let subscription = networkHelper.requests.subscribe { request in
            if case let .post(_, body) = request,
               let visitorId = body[TealiumDataKey.visitorId] as? String {
                if visitorId == "visitor1" {
                    firstVisitorSent.fulfill()
                } else if visitorId == "visitor2" {
                    secondVisitorSent.fulfill()
                }
            }
        }
        _ = collect.dispatch([
            TealiumDispatch(name: "event1", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event2", data: [TealiumDataKey.visitorId: "visitor2"])
        ], completion: { _ in })
        waitForExpectations(timeout: 1.0)
        subscription.dispose()
    }

    func test_multiple_dispatches_with_same_visitorIds_are_sent_in_the_same_batch() {
        let firstVisitorSent = expectation(description: "The POST request for the first visitor is sent")
        let secondVisitorSent = expectation(description: "The POST request for the second visitor is sent")
        let subscription = networkHelper.requests.subscribe { request in
            if case let .post(_, body) = request,
               let shared = body["shared"] as? [String: Any],
               let visitorId = shared[TealiumDataKey.visitorId] as? String {
                if visitorId == "visitor1" {
                    firstVisitorSent.fulfill()
                } else if visitorId == "visitor2" {
                    secondVisitorSent.fulfill()
                }
            }
        }
        _ = collect.dispatch([
            TealiumDispatch(name: "event1", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event2", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event3", data: [TealiumDataKey.visitorId: "visitor2"]),
            TealiumDispatch(name: "event4", data: [TealiumDataKey.visitorId: "visitor2"])
        ], completion: { _ in })
        waitForExpectations(timeout: 1.0)
        subscription.dispose()
    }

    func test_multiple_dispatches_with_same_visitorIds_only_complete_with_the_batched_events() {
        let firstVisitorSent = expectation(description: "The POST request for the first visitor is sent")
        let secondVisitorSent = expectation(description: "The POST request for the second visitor is sent")
        _ = collect.dispatch([
            TealiumDispatch(name: "event1", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event2", data: [TealiumDataKey.visitorId: "visitor1"]),
            TealiumDispatch(name: "event3", data: [TealiumDataKey.visitorId: "visitor2"])
        ], completion: { events in
            let visitorIdsArray = events.map { $0.eventData[TealiumDataKey.visitorId] as? String ?? "" }
            XCTAssertEqual(Set(visitorIdsArray).count, 1, "All visitorIds should be the same in this batch")
            if visitorIdsArray[0] == "visitor1" {
                firstVisitorSent.fulfill()
            } else if visitorIdsArray[0] == "visitor2" {
                secondVisitorSent.fulfill()
            }
        })
        waitForExpectations(timeout: 1.0)
    }

    func test_disposed_dispatch_are_not_completed() {
        let postRequestCancelled = expectation(description: "The POST request is cancelled")
        networkHelper.delay = 500
        let subscription = collect.dispatch([stubDispatches[0]], completion: { dispatches in
            XCTAssertEqual(dispatches.count, 0)
            postRequestCancelled.fulfill()
        })
        subscription.dispose()
        waitForExpectations(timeout: 1.0)
    }
}
