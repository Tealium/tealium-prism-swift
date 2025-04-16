//
//  SceneDelegateProxyTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

@available(iOS 13, *)
class SceneDelegateProxyTests: BaseProxyTests {

    func test_onOpenUrl_is_called_with_connectSessionOpenUrl() throws {
        let onOpenUrlReceived = expectation(description: "OnOpenUrl received")
        let inputUrl = "https://my-test-app.com/?\(#function)"
        XCTAssertNoThrow(try sendWillConnectWithOptions(urlString: inputUrl, isActivity: false))
        TealiumDelegateProxy.onOpenUrl?
            .subscribeOn(queue)
            .subscribe { url, _ in
                XCTAssertEqual(url.absoluteString, inputUrl)
                onOpenUrlReceived.fulfill()
            }.addTo(disposer)
        waitOnQueue(queue: queue)
    }

    func test_onOpenUrl_is_called_with_connectSessionUniversalLink() {
        let onOpenUrlReceived = expectation(description: "OnOpenUrl received")
        let inputUrl = "https://my-test-app.com/?\(#function)"
        XCTAssertNoThrow(try sendWillConnectWithOptions(urlString: inputUrl, isActivity: true))
        TealiumDelegateProxy.onOpenUrl?
            .subscribeOn(queue)
            .subscribe { url, _ in
                XCTAssertEqual(url.absoluteString, inputUrl)
                onOpenUrlReceived.fulfill()
            }.addTo(disposer)
        waitOnQueue(queue: queue)
    }

    func sendWillConnectWithOptions(urlString: String, isActivity: Bool) throws {
        guard let url = URL(string: urlString) else {
            throw ParsingError.invalidUrl(urlString)
        }
        UIApplication.shared.manualSceneWillConnect(with: MockConnectionOptions(url: url,
                                                                                isActivity: isActivity))
    }
}
