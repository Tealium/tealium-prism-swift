//
//  TealiumDelegateProxyTests.swift
//  tealium-prism
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class BaseProxyTests: XCTestCase {
    static var testNumber = 0
    let queue = TealiumQueue.worker
    let disposer = DisposableContainer()

    override func tearDown() {
        disposer.dispose()
        // Some tests replace it, so restore the default one for whatever runs next.
        TealiumDelegateProxy.configuration = .init()
    }
}

class TealiumDelegateProxyTests: BaseProxyTests {

    func test_onOpenUrl_is_called_with_openUrlEvent() {
        let onOpenUrlReceived = expectation(description: "OnOpenUrl received")
        let inputUrl = "https://my-test-app.com/?\(#function)"
        XCTAssertNoThrow(try sendOpenUrlEvent(urlString: inputUrl))
        TealiumDelegateProxy.onOpenUrl?
            .subscribeOn(queue)
            .subscribe { url, _ in
                XCTAssertEqual(url.absoluteString, inputUrl)
                onOpenUrlReceived.fulfill()
            }.addTo(disposer)
        waitOnQueue(queue: queue)
    }

    func test_onOpenUrl_is_called_with_universalLink() {
        let onOpenUrlReceived = expectation(description: "OnOpenUrl received")
        let inputUrl = "https://my-test-app.com/?\(#function)"
        XCTAssertNoThrow(try sendContinueUserActivityEvent(urlString: inputUrl))
        TealiumDelegateProxy.onOpenUrl?
            .subscribeOn(queue)
            .subscribe { url, _ in
                XCTAssertEqual(url.absoluteString, inputUrl)
                onOpenUrlReceived.fulfill()
            }.addTo(disposer)
        waitOnQueue(queue: queue)
    }

    func test_onOpenUrl_is_nil_when_autotracking_disabled() {
        let mockBundle = MockBundle(infoDictionary: ["TealiumAutotrackingDeepLinkEnabled": false])
        TealiumDelegateProxy.configuration = .init(bundle: mockBundle)
        XCTAssertNil(TealiumDelegateProxy.onOpenUrl)
    }
}
