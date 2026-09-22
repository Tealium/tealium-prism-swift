//
//  Lifecycle+TrackerTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 10/12/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

// Exercises `ModuleManager`'s readiness gate (MT-2154) through the real `LifecycleModule`, not
// Lifecycle's event logic - Lifecycle is the shipped module that tracks from its own init, which
// is what makes it a useful stand-in for a module tracking mid-settings-pass.
final class LifecycleTrackerTests: XCTestCase {

    @StateSubject([TransformationSettings(id: "transformation1",
                                          transformerId: "transformer1",
                                          scope: .allDispatchers)])
    var transformations
    let config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [
                                MockDispatcher.factory(),
                                Modules.lifecycle(forcingSettings: { enforcedSettings in
                                    enforcedSettings.setEnabled(true).setOrder(0)
                                }),
                                Modules.appData(forcingSettings: { enforcedSettings in
                                    enforcedSettings.setOrder(1)
                                })
                               ],
                               settingsFile: "",
                               settingsUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let queue = TealiumQueue.main
    let moduleManager = ModuleManager()
    @StateSubject(SDKSettings())
    var sdkSettings
    var coreSettings: ObservableState<CoreSettings> {
        sdkSettings.mapState(transform: { $0.core })
    }
    lazy var queueManager = MockQueueManager(processors: TealiumImpl.queueProcessors(from: moduleManager.observeModules { $0 as? Dispatcher }, addingConsent: true),
                                             queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                                 maxQueueSize: 10,
                                                                                 expiration: 1.days),
                                             coreSettings: coreSettings,
                                             logger: nil)
    lazy var barrierCoordinator = BarrierCoordinator(onScopedBarriers: Observables.just([]),
                                                     onApplicationStatus: config.appStatusListener.onApplicationStatus,
                                                     queueMetrics: queueManager,
                                                     queue: queue)
    lazy var transformerCoordinator = TransformerCoordinator(onTransformers: Observables.just([]),
                                                             transformations: transformations,
                                                             queue: queue,
                                                             logger: nil)
    lazy var tracker = TrackerImpl(onCollectors: moduleManager.observeModules { $0 as? Collector },
                                   loadRuleEngine: LoadRuleEngine(sdkSettings: sdkSettings, logger: nil),
                                   dispatchManager: dispatchManager,
                                   sessionManager: MockSessionManager(databaseProvider: databaseProvider),
                                   logger: nil)
    lazy var context = MockContext(moduleManager: moduleManager,
                                   config: config,
                                   coreSettings: coreSettings,
                                   tracker: tracker,
                                   transformerRegistrar: transformerCoordinator,
                                   databaseProvider: databaseProvider,
                                   queue: queue)
    lazy var dispatchManager = getDispatchManager()
    func getDispatchManager() -> DispatchManager {
        DispatchManager(loadRuleEngine: LoadRuleEngine(sdkSettings: sdkSettings, logger: nil),
                        onDispatchers: moduleManager.observeModules { $0 as? Dispatcher },
                        consentManager: nil,
                        queueManager: queueManager,
                        barrierCoordinator: barrierCoordinator,
                        transformerCoordinator: transformerCoordinator,
                        mappingsEngine: MappingsEngine(mappings: .constant([:])),
                        logger: nil)
    }

    override func setUp() {
        super.setUp()
        _sdkSettings.value = SDKSettings(config.getEnforcedSDKSettings())
        moduleManager.updateSettings(context: context, settings: sdkSettings.value)
    }

    override func tearDown() {
        dispatchManager.stopDispatchLoop()
    }

    // Launch is tracked synchronously from `LifecycleModule.init`, because
    // `ApplicationStatusListener.onApplicationStatus` is a `ReplaySubject` seeded with `.initialized`;
    // the appVersion assertion holds only because `TrackerImpl.track` waits for the settings pass to
    // complete before collecting.
    func test_launch_gets_dispatched_on_application_start_and_contains_appData_collector_data() {
        let gotDispatched = expectation(description: "Launch has been dispatched")
        let eventContainsAppData = expectation(description: "Launch event contains app data")
        moduleManager.observeModule(MockDispatcher.self).compactMap { $0 }.flatMapLatest(\.onDispatch)
            .subscribeOnce { dispatches in
                let dispatch = dispatches[0]
                XCTAssertEqual(dispatch.name, "launch")
                gotDispatched.fulfill()
                XCTAssertNotNil(dispatch.payload.getDataItem(key: TealiumDataKey.appVersion))
                eventContainsAppData.fulfill()
            }
        waitForLongTimeout()
    }
}
