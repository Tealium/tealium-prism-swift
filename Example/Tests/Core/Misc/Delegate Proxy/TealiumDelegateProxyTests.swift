//
//  TealiumDelegateProxyTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

enum SceneDelegateProxyError: Error {
    case sceneDelegateNotFound
    case appDelegateNotFound
}

class BaseProxyTests: XCTestCase {
    static var testNumber = 0
    let queue = TealiumQueue.worker
    let disposer = DisposeContainer()

    override func tearDown() {
        disposer.dispose()
    }
    func sendOpenUrlEvent(urlString: String) throws {
        let url = try urlString.asUrl()
        if #available(iOS 13.0, *), TealiumDelegateProxy.sceneEnabled {
            guard let scene = UIApplication.shared.connectedScenes.first,
                  let sceneDelegate = scene.delegate else {
                throw SceneDelegateProxyError.sceneDelegateNotFound
            }
            sceneDelegate.scene?(scene, openURLContexts: Set<UIOpenURLContext>([MockOpenUrlContext(url: url)]))
        } else {
            guard let appDelegate = UIApplication.shared.delegate else {
                throw SceneDelegateProxyError.appDelegateNotFound
            }
            _ = appDelegate.application?(UIApplication.shared, open: url, options: [:])
        }
    }

    func sendContinueUserActivityEvent(urlString: String) throws {
        let url = try urlString.asUrl()
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = url
        if #available(iOS 13.0, *), TealiumDelegateProxy.sceneEnabled {
            UIApplication.shared.manualSceneContinueUserActivity(activity)
        } else {
            UIApplication.shared.manualContinueUserActivity(activity)
        }
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
