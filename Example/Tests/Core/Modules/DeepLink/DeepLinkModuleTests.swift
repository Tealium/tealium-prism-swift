//
//  DeepLinkModuleTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DeepLinkModuleTests: DeepLinkBaseTests {
    func test_the_module_id_is_correct() {
        XCTAssertNotNil(context().moduleStoreProvider.modulesRepository.getModules()[DeepLinkModule.moduleType])
    }

    func test_handle_joins_trace() throws {
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()
        try deepLink.handle(link: link)
        XCTAssertEqual(try deepLink.getTrace().collect(dispatchContext).get(key: TealiumDataKey.traceId), testTraceId)
    }

    func test_handle_leaves_trace() throws {
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)&leave_trace".asUrl()
        try deepLink.getTrace().join(id: testTraceId)
        XCTAssertEqual(try deepLink.getTrace().collect(dispatchContext).get(key: TealiumDataKey.traceId), testTraceId)
        try deepLink.handle(link: link)
        XCTAssertNil(try deepLink.getTrace().collect(dispatchContext).getDataItem(key: TealiumDataKey.traceId))
    }

    func test_handle_does_not_join_trace_if_deepLink_trace_disabled() throws {
        updateSettings(DeepLinkSettingsBuilder().setDeepLinkTraceEnabled(false))
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()
        try deepLink.handle(link: link)
        XCTAssertNil(try deepLink.getTrace().collect(dispatchContext).getDataItem(key: TealiumDataKey.traceId))
    }

    func test_handle_kills_visitor_session_and_leaves() throws {
        let visitorSessionKilled = expectation(description: "Session killed")
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)&leave_trace&kill_visitor_session".asUrl()
        try deepLink.getTrace().join(id: testTraceId)
        XCTAssertEqual(try deepLink.getTrace().collect(dispatchContext).get(key: TealiumDataKey.traceId), testTraceId)
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, TealiumKey.killVisitorSession)
            visitorSessionKilled.fulfill()
        }
        try deepLink.handle(link: link)
        XCTAssertNil(try deepLink.getTrace().collect(dispatchContext).getDataItem(key: TealiumDataKey.traceId))
        waitForDefaultTimeout()
    }

    func test_handle_only_kills_visitor_session() throws {
        let visitorSessionKilled = expectation(description: "Session killed")
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)&kill_visitor_session".asUrl()
        try deepLink.getTrace().join(id: testTraceId)
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, TealiumKey.killVisitorSession)
            visitorSessionKilled.fulfill()
        }
        try deepLink.handle(link: link)
        XCTAssertEqual(try deepLink.getTrace().collect(dispatchContext).get(key: TealiumDataKey.traceId), testTraceId)
        waitForDefaultTimeout()
    }

    func test_handle_sends_deep_link_event_if_enabled() throws {
        let deepLinkEventSent = expectation(description: "Deep link event was sent")
        updateSettings(DeepLinkSettingsBuilder().setSendDeepLinkEvent(true))
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)&utm_param_1=hello&utm_param_2=test".asUrl()
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, TealiumKey.deepLink)
            deepLinkEventSent.fulfill()
        }
        try deepLink.handle(link: link)
        waitForDefaultTimeout()
    }

    func test_handle_registers_referrer_url() throws {
        let referrer = "https://google.com"
        let link = try "https://tealium.com".asUrl()
        try deepLink.handle(link: link, referrer: .fromUrl(URL(string: referrer)))
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: TealiumDataKey.deepLinkReferrerUrl), referrer)
    }

    func test_handle_registers_referrer_app() throws {
        let referrer = "com.tealium.someApp"
        let link = try "https://tealium.com".asUrl()
        try deepLink.handle(link: link, referrer: .fromAppId(referrer))
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: TealiumDataKey.deepLinkReferrerApp), referrer)
    }

    func test_handle_registers_query_params() throws {
        let link1 = try "https://tealium.com?queryParam1=value1&queryParam2=value2".asUrl()
        try deepLink.handle(link: link1)
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: "deep_link_param_queryParam1"), "value1")
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: "deep_link_param_queryParam2"), "value2")
    }

    func test_handle_two_deep_links_overwrites_old_query_params() throws {
        let link1 = try "https://tealium.com?queryParam1=value1".asUrl()
        let link2 = try "https://tealium.com?queryParam1=value2".asUrl()
        try deepLink.handle(link: link1)
        try deepLink.handle(link: link2)
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: "deep_link_param_queryParam1"), "value2")
    }

    func test_collect_returns_empty_data_object_when_source_is_deep_link_handler() throws {
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()
        try deepLink.handle(link: link)
        XCTAssertEqual(deepLink.collect(DispatchContext(source: .module(DeepLinkModule.self), initialData: [:])).count, 0)
    }
}
