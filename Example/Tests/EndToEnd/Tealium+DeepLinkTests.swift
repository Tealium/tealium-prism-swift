//
//  Tealium+DeepLinkTests.swift
//  tealium-prism
//
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if os(iOS)
@testable import TealiumPrism
import XCTest

final class TealiumDeepLinkTests: TealiumBaseTests {

    override func tearDown() {
        super.tearDown()
        // The swizzled delegate is process-wide, so leave the default configuration for the next test.
        TealiumDelegateProxy.configuration = .init()
    }

    /**
     * Reproduces an app launched by a deep link: the OS delivers the URL to the swizzled delegate before
     * Tealium is created, `onOpenUrl` caches it, and `DeepLinkModule` gets it replayed from its `init` -
     * while `ModuleManager` is still building the modules of its first settings pass. The deep link must
     * wait for the modules instead of concluding that the Trace module is disabled.
     */
    func test_deep_link_delivered_before_modules_are_published_joins_trace() throws {
        let traceChecked = expectation(description: "Trace state checked")
        let traceId = "traceIdBeforeInit"
        config.addModule(Modules.deepLink())
        config.addModule(Modules.trace())
        try sendOpenUrlEvent(urlString: "tealium://launch?tealium_trace_id=\(traceId)")
        // The URL is cached before Tealium starts up.
        waitForDispatchQueueToBeEmpty()
        let teal = createTealium()
        teal.proxy.getProxiedObject { impl in
            guard let impl else {
                XCTFail("Tealium implementation not created")
                return
            }
            let trace: TraceModule? = impl.moduleManager.getModule()
            XCTAssertEqual(trace?.traceId, traceId)
            traceChecked.fulfill()
        }
        waitOnQueue(queue: queue, timeout: Self.longTimeout)
    }
}
#endif
