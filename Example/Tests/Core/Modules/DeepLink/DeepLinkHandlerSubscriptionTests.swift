//
//  DeepLinkHandlerSubscriptionTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 17/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DeepLinkHandlerSubscriptionTests: DeepLinkHandlerBaseTests {
    @ToAnyObservable<ReplaySubject<(URL, Referrer?)>>(ReplaySubject<(URL, Referrer?)>())
    var onOpenUrl: Observable<(URL, Referrer?)>

    func test_deep_link_is_handled_by_module_when_url_is_published() throws {
        let context = context()
        let deeplinkDataStore = try context.moduleStoreProvider.getModuleStore(name: DeepLinkHandlerModule.id)
        deepLink = DeepLinkHandlerModule(dataStore: deeplinkDataStore,
                                         tracker: context.tracker,
                                         modulesManager: context.modulesManager,
                                         configuration: DeepLinkHandlerConfiguration(configuration: [:]),
                                         onOpenUrl: onOpenUrl)
        let urlString = "https://tealium.com"
        let referrer = "https://google.com"
        let link = try urlString.asUrl()
        _onOpenUrl.publish((link, .fromUrl(URL(string: referrer))))
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: TealiumDataKey.deepLinkURL), urlString)
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: TealiumDataKey.deepLinkReferrerUrl), referrer)
    }

    func test_deep_link_error_is_logged_when_handle_throws() throws {
        let errorLogged = expectation(description: "Error logged")
        config.modules = [] // remove trace module so that we caught an error when trying to get trace
        let context = context()
        let deeplinkDataStore = try context.moduleStoreProvider.getModuleStore(name: DeepLinkHandlerModule.id)
        manager.updateSettings(context: context, settings: SDKSettings([:]))
        let logger = MockLogger()
        deepLink = DeepLinkHandlerModule(dataStore: deeplinkDataStore,
                                         tracker: context.tracker,
                                         modulesManager: context.modulesManager,
                                         configuration: DeepLinkHandlerConfiguration(configuration: [:]),
                                         onOpenUrl: onOpenUrl,
                                         logger: logger)
        let urlString = "https://tealium.com?tealium_trace_id=12345" // add trace id to fire trace actions
        let referrer = "https://google.com"
        let link = try urlString.asUrl()
        logger.handler.onLogged.subscribeOnce { logEvent in
            guard logEvent.level == .error, logEvent.category == DeepLinkHandlerModule.id else {
                XCTFail("Invalid log event")
                return
            }
            errorLogged.fulfill()
        }
        _onOpenUrl.publish((link, .fromUrl(URL(string: referrer))))
        waitForDefaultTimeout()
    }
}
