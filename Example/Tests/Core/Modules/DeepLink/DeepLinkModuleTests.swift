//
//  DeepLinkModuleTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DeepLinkModuleTests: DeepLinkBaseTests {
    func test_the_module_id_is_correct() {
        XCTAssertNotNil(context().moduleStoreProvider.modulesRepository.getModules()[DeepLinkModule.moduleType])
    }

    func test_handle_joins_trace() throws {
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()
        handleAndWait(link: link)
        XCTAssertEqual(joinedTraceId, testTraceId)
    }

    func test_handle_leaves_trace() throws {
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)&leave_trace".asUrl()
        try XCTUnwrap(trace).join(id: testTraceId)
        XCTAssertEqual(joinedTraceId, testTraceId)
        handleAndWait(link: link)
        XCTAssertNil(joinedTraceId)
    }

    func test_handle_does_not_join_trace_if_deepLink_trace_disabled() throws {
        updateSettings(DeepLinkSettingsBuilder().setDeepLinkTraceEnabled(false))
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()
        handleAndWait(link: link)
        XCTAssertNil(joinedTraceId)
    }

    func test_handle_ends_visitor_session_and_leaves() throws {
        let visitorSessionEnded = expectation(description: "Session ended")
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)&leave_trace&kill_visitor_session".asUrl()
        try XCTUnwrap(trace).join(id: testTraceId)
        XCTAssertEqual(joinedTraceId, testTraceId)
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, TealiumConstants.forceEndOfVisitQueryParam)
            visitorSessionEnded.fulfill()
        }
        handleAndWait(link: link)
        XCTAssertNil(joinedTraceId)
        waitForDefaultTimeout()
    }

    func test_handle_only_ends_visitor_session() throws {
        let visitorSessionEnded = expectation(description: "Session ended")
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)&kill_visitor_session".asUrl()
        try XCTUnwrap(trace).join(id: testTraceId)
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, TealiumConstants.forceEndOfVisitQueryParam)
            visitorSessionEnded.fulfill()
        }
        handleAndWait(link: link)
        XCTAssertEqual(joinedTraceId, testTraceId)
        waitForDefaultTimeout()
    }

    func test_handle_sends_deep_link_event_if_enabled() throws {
        let deepLinkEventSent = expectation(description: "Deep link event was sent")
        updateSettings(DeepLinkSettingsBuilder().setSendDeepLinkEvent(true))
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)&utm_param_1=hello&utm_param_2=test".asUrl()
        tracker.onTrack.subscribeOnce { dispatch in
            XCTAssertEqual(dispatch.name, TealiumConstants.deepLinkEvent)
            deepLinkEventSent.fulfill()
        }
        handleAndWait(link: link)
        waitForDefaultTimeout()
    }

    /// The trace has to be joined before the event is tracked, or the event lands outside the trace.
    func test_handle_joins_trace_before_sending_the_deep_link_event() throws {
        let deepLinkEventSent = expectation(description: "Deep link event was sent")
        updateSettings(DeepLinkSettingsBuilder().setSendDeepLinkEvent(true))
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()
        tracker.onTrack.subscribeOnce { [self] dispatch in
            XCTAssertEqual(dispatch.name, TealiumConstants.deepLinkEvent)
            XCTAssertEqual(joinedTraceId, testTraceId, "The trace must already be joined")
            deepLinkEventSent.fulfill()
        }
        handleAndWait(link: link)
        waitForDefaultTimeout()
    }

    func test_handle_fails_when_trace_is_not_enabled() throws {
        let handled = expectation(description: "Handling completed")
        config.modules = [] // no trace module: the failure must be reported, not swallowed
        let manager = ModuleManager()
        let moduleContext = MockContext(moduleManager: manager,
                                        config: config,
                                        tracker: tracker,
                                        databaseProvider: dbProvider,
                                        queue: queue)
        manager.updateSettings(context: moduleContext, settings: SDKSettings(config.getEnforcedSDKSettings()))
        deepLink = makeDeepLink(context: moduleContext)
        deepLink.handle(link: try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()) { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertEqual(module, TraceModule.moduleType)
            }
            handled.fulfill()
        }
        waitForDefaultTimeout()
    }

    /// A pending lookup must fail rather than leave its caller waiting forever.
    func test_handle_fails_when_shut_down_while_waiting_for_the_trace_module() throws {
        let handled = expectation(description: "Handling completed")
        let manager = ModuleManager() // no settings pass: the lookup stays pending
        let moduleContext = MockContext(moduleManager: manager,
                                        config: config,
                                        tracker: tracker,
                                        databaseProvider: dbProvider,
                                        queue: queue)
        deepLink = makeDeepLink(context: moduleContext)
        deepLink.handle(link: try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()) { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertModuleShutdown(error, module: self.deepLink.id)
            }
            handled.fulfill()
        }
        queue.dispatchQueue.sync { }
        deepLink.shutdown()
        waitForDefaultTimeout()
    }

    /// Releasing the module counts as a shutdown for whatever it left pending.
    func test_handle_fails_when_the_module_is_released_while_waiting_for_the_trace_module() throws {
        let handled = expectation(description: "Handling completed")
        let manager = ModuleManager() // no settings pass: the lookup stays pending
        let moduleContext = MockContext(moduleManager: manager,
                                        config: config,
                                        tracker: tracker,
                                        databaseProvider: dbProvider,
                                        queue: queue)
        var releasable: DeepLinkModule? = makeDeepLink(context: moduleContext)
        releasable?.handle(link: try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()) { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertModuleShutdown(error, module: DeepLinkModule.moduleType)
            }
            handled.fulfill()
        }
        queue.dispatchQueue.sync { }
        releasable = nil
        waitForDefaultTimeout()
    }

    /**
     * The shutdown guard and the module lookup must not both answer the same call: the guard fails
     * the lookup as the module is added to an already disposed container, and a lookup started on
     * top of that would complete a second time and join the trace behind the caller's back.
     */
    func test_handle_after_shutdown_completes_exactly_once() throws {
        let handled = expectation(description: "Handling completed")
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()
        // On the Tealium queue, as in production: the module lookup resolves synchronously there,
        // which is what can complete the call a second time.
        queue.dispatchQueue.sync {
            deepLink.shutdown()
            deepLink.handle(link: link) { result in
                XCTAssertResultIsFailure(result) { error in
                    XCTAssertModuleShutdown(error, module: self.deepLink.id)
                }
                handled.fulfill()
            }
        }
        waitForDefaultTimeout()
        XCTAssertNil(joinedTraceId)
    }

    func test_handle_registers_referrer_url() throws {
        let referrer = "https://google.com"
        let link = try "https://tealium.com".asUrl()
        handleAndWait(link: link, referrer: .fromUrl(URL(string: referrer)))
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: TealiumDataKey.deepLinkReferrerUrl), referrer)
    }

    func test_handle_registers_referrer_app() throws {
        let referrer = "com.tealium.someApp"
        let link = try "https://tealium.com".asUrl()
        handleAndWait(link: link, referrer: .fromAppId(referrer))
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: TealiumDataKey.deepLinkReferrerApp), referrer)
    }

    func test_handle_registers_query_params() throws {
        let link1 = try "https://tealium.com?queryParam1=value1&queryParam2=value2".asUrl()
        handleAndWait(link: link1)
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: "deep_link_param_queryParam1"), "value1")
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: "deep_link_param_queryParam2"), "value2")
    }

    func test_handle_two_deep_links_overwrites_old_query_params() throws {
        let link1 = try "https://tealium.com?queryParam1=value1".asUrl()
        let link2 = try "https://tealium.com?queryParam1=value2".asUrl()
        handleAndWait(link: link1)
        handleAndWait(link: link2)
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: "deep_link_param_queryParam1"), "value2")
    }

    func test_collect_returns_empty_data_object_when_source_is_deep_link_handler() throws {
        let link = try "https://tealium.com?tealium_trace_id=\(testTraceId)".asUrl()
        handleAndWait(link: link)
        XCTAssertEqual(deepLink.collect(DispatchContext(source: .module(DeepLinkModule.self), initialData: [:])).count, 0)
    }
}
