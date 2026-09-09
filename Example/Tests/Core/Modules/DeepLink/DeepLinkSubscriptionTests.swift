//
//  DeepLinkSubscriptionTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DeepLinkSubscriptionTests: DeepLinkBaseTests {
    @ReplaySubject<(URL, Referrer?)> var onOpenUrl

    func test_deep_link_is_handled_by_module_when_url_is_emitted() throws {
        let context = context()
        let deepLinkDataStore = try context.moduleStoreProvider.getModuleStore(name: DeepLinkModule.moduleType)
        deepLink = DeepLinkModule(dataStore: deepLinkDataStore,
                                  tracker: context.tracker,
                                  moduleManager: context.moduleManager,
                                  configuration: DeepLinkModuleConfiguration(configuration: [:]),
                                  onOpenUrl: onOpenUrl)
        let urlString = "https://tealium.com"
        let referrer = "https://google.com"
        let link = try urlString.asUrl()
        _onOpenUrl.onNext((link, .fromUrl(URL(string: referrer))))
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: TealiumDataKey.deepLinkURL), urlString)
        XCTAssertEqual(deepLink.collect(dispatchContext).get(key: TealiumDataKey.deepLinkReferrerUrl), referrer)
    }

    func test_deep_link_is_ignored_after_shutdown() throws {
        let context = context()
        let deepLinkDataStore = try context.moduleStoreProvider.getModuleStore(name: DeepLinkModule.moduleType)
        deepLink = DeepLinkModule(dataStore: deepLinkDataStore,
                                  tracker: context.tracker,
                                  moduleManager: context.moduleManager,
                                  configuration: DeepLinkModuleConfiguration(configuration: [:]),
                                  onOpenUrl: onOpenUrl)
        deepLink.shutdown()
        _onOpenUrl.onNext((try "https://tealium.com".asUrl(), nil))
        // The subscription is gone with the shutdown, so nothing was collected from the link.
        XCTAssertEqual(deepLink.collect(dispatchContext).count, 0)
    }

    func test_deep_link_error_is_logged_when_handle_throws() throws {
        let errorLogged = expectation(description: "Error logged")
        config.modules = [] // remove trace module so that we catch an error when trying to get trace
        let context = context()
        let deepLinkDataStore = try context.moduleStoreProvider.getModuleStore(name: DeepLinkModule.moduleType)
        manager.updateSettings(context: context, settings: SDKSettings([:]))
        let logger = MockLogger()
        deepLink = DeepLinkModule(dataStore: deepLinkDataStore,
                                  tracker: context.tracker,
                                  moduleManager: context.moduleManager,
                                  configuration: DeepLinkModuleConfiguration(configuration: [:]),
                                  onOpenUrl: onOpenUrl,
                                  logger: logger)
        let urlString = "https://tealium.com?tealium_trace_id=12345" // add trace id to fire trace actions
        let referrer = "https://google.com"
        let link = try urlString.asUrl()
        logger.handler.onLogged.subscribeOnce { logEvent in
            guard logEvent.level == .error, logEvent.category == DeepLinkModule.moduleType else {
                XCTFail("Invalid log event")
                return
            }
            errorLogged.fulfill()
        }
        _onOpenUrl.onNext((link, .fromUrl(URL(string: referrer))))
        waitForDefaultTimeout()
    }

    /**
     * Reproduces an app launched by a deep link: `TealiumDelegateProxy.onOpenUrl` is a `ReplaySubject`,
     * so the URL is already cached when the module system starts up and gets replayed synchronously from
     * `DeepLinkModule.init`. At that point `ModuleManager` hasn't published its first modules pass yet,
     * so the trace lookup must wait for it instead of concluding that the Trace module is disabled.
     */
    func test_deep_link_joins_trace_when_url_arrives_before_modules_are_published() throws {
        config.modules = [Modules.trace()]
        // A manager whose first settings pass hasn't run yet, unlike the one built by the base setUp.
        let manager = ModuleManager(queue: queue)
        let moduleContext = MockContext(moduleManager: manager,
                                        config: config,
                                        tracker: tracker,
                                        databaseProvider: dbProvider,
                                        queue: queue)
        let store = try moduleContext.moduleStoreProvider.getModuleStore(name: DeepLinkModule.moduleType)
        let link = try "tealium://launch?tealium_trace_id=\(testTraceId)".asUrl()
        // On the Tealium queue, as in production: the replayed URL reaches the module synchronously
        // from its init, and its trace lookup subscribes while the pass is still running.
        queue.dispatchQueue.sync {
            // The deep link is already waiting when the module is created.
            _onOpenUrl.onNext((link, nil))
            deepLink = DeepLinkModule(dataStore: store,
                                      tracker: tracker,
                                      moduleManager: manager,
                                      configuration: DeepLinkModuleConfiguration(configuration: [:]),
                                      onOpenUrl: onOpenUrl)
            manager.updateSettings(context: moduleContext,
                                   settings: SDKSettings(config.getEnforcedSDKSettings()))
        }
        let trace: TraceModule? = manager.getModule()
        XCTAssertEqual(trace?.traceId, testTraceId)
    }

    /**
     * The shape of an app that starts the SDK late - after a consent screen, a remote config fetch or
     * a login. The deep link that launched the app is delivered long before `Tealium` exists, so the
     * very first settings pass creates `DeepLink` and `Trace` with the URL already waiting.
     *
     * Unlike the test above, the module is created **by the pass**, which is the only way modules are
     * created in production, and no earlier pass has run.
     */
    func test_deep_link_joins_trace_when_url_arrives_before_the_first_settings_pass() throws {
        let manager = ModuleManager(queue: queue)
        // The deep link arrives while the SDK has not been created yet.
        let link = try "tealium://launch?tealium_trace_id=\(testTraceId)".asUrl()
        config.modules = [Modules.trace(), DeepLinkModuleFactory(enforcedSettings: [:], onOpenUrl: onOpenUrl)]
        // On the Tealium queue, as in production, so the pass creates the module that is already
        // holding the deep link and its trace lookup runs inside that pass.
        queue.dispatchQueue.sync {
            _onOpenUrl.onNext((link, nil))
            manager.updateSettings(context: passContext(for: manager),
                                   settings: SDKSettings(config.getEnforcedSDKSettings()))
        }
        let trace: TraceModule? = manager.getModule()
        XCTAssertEqual(trace?.traceId, testTraceId)
    }

    /**
     * The shape of an app whose modules come from remote settings: a first settings pass runs with
     * whatever is configured locally, the deep link arrives while there is no DeepLink module yet,
     * and `DeepLink` and `Trace` are both created by a later pass.
     *
     * The module is created **by the pass**, as it always is in production, so the answer of the
     * earlier pass must not be replayed to it - back then Trace really wasn't enabled.
     */
    func test_deep_link_joins_trace_when_url_arrives_between_two_settings_passes() throws {
        let manager = ModuleManager(queue: queue)
        let link = try "tealium://launch?tealium_trace_id=\(testTraceId)".asUrl()
        // On the Tealium queue, as in production: the module of the second pass subscribes while that
        // pass runs, so it would be handed the answer of the first pass if it were still cached.
        queue.dispatchQueue.sync {
            // First pass: neither Trace nor DeepLink is configured.
            config.modules = []
            manager.updateSettings(context: passContext(for: manager),
                                   settings: SDKSettings(config.getEnforcedSDKSettings()))
            // The deep link arrives before the module that handles it exists.
            _onOpenUrl.onNext((link, nil))
            // Second pass: Trace and DeepLink arrive together, the way remote settings deliver them.
            config.modules = [Modules.trace(), DeepLinkModuleFactory(enforcedSettings: [:], onOpenUrl: onOpenUrl)]
            manager.updateSettings(context: passContext(for: manager),
                                   settings: SDKSettings(config.getEnforcedSDKSettings()))
        }
        let trace: TraceModule? = manager.getModule()
        XCTAssertEqual(trace?.traceId, testTraceId)
    }

    /// A context carrying the current `config`, since each pass may enable different modules.
    private func passContext(for manager: ModuleManager) -> TealiumContext {
        MockContext(moduleManager: manager,
                    config: config,
                    tracker: tracker,
                    databaseProvider: dbProvider,
                    queue: queue)
    }
}
