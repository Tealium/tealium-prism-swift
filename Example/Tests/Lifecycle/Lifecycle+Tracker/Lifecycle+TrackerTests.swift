//
//  Lifecycle+TrackerTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 10/12/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class LifecycleTrackerTests: XCTestCase {

    @StateSubject([TransformationSettings(id: "transformation1",
                                          transformerId: "transformer1",
                                          scopes: [.afterCollectors, .allDispatchers])])
    var transformations: ObservableState<[TransformationSettings]>
    let config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [
                                MockDispatcher.factory(),
                                Modules.lifecycle(forcingSettings: { enforcedSettings in
                                    enforcedSettings.setEnabled(true)
                                }),
                                Modules.appData()
                               ],
                               settingsFile: "",
                               settingsUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let queue = TealiumQueue.main
    lazy var modulesManager = ModulesManager(queue: queue)
    @StateSubject(SDKSettings())
    var sdkSettings: ObservableState<SDKSettings>
    var coreSettings: ObservableState<CoreSettings> {
        sdkSettings.mapState(transform: { $0.core })
    }
    lazy var queueManager = MockQueueManager(processors: TealiumImpl.queueProcessors(from: modulesManager.modules, addingConsent: true),
                                             queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                                 maxQueueSize: 10,
                                                                                 expiration: 1.days),
                                             coreSettings: coreSettings,
                                             logger: nil)
    lazy var barrierCoordinator = BarrierCoordinator(onScopedBarriers: .Just([]),
                                                     onApplicationStatus: config.appStatusListener.onApplicationStatus,
                                                     queueMetrics: queueManager,
                                                     debouncer: MockInstantDebouncer(),
                                                     queue: queue)
    lazy var transformerCoordinator = TransformerCoordinator(transformers: .constant([]),
                                                             transformations: transformations,
                                                             queue: queue,
                                                             logger: nil)
    lazy var tracker = TrackerImpl(modules: modulesManager.modules,
                                   loadRuleEngine: LoadRuleEngine(sdkSettings: sdkSettings, logger: nil),
                                   dispatchManager: dispatchManager,
                                   sessionManager: MockSessionManager(databaseProvider: databaseProvider),
                                   logger: nil)
    lazy var context = MockContext(modulesManager: modulesManager,
                                   config: config,
                                   coreSettings: coreSettings,
                                   tracker: tracker,
                                   transformerRegistry: transformerCoordinator,
                                   databaseProvider: databaseProvider,
                                   queue: queue)
    lazy var dispatchManager = getDispatchManager()
    func getDispatchManager() -> DispatchManager {
        DispatchManager(loadRuleEngine: LoadRuleEngine(sdkSettings: sdkSettings, logger: nil),
                        modulesManager: modulesManager,
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
        modulesManager.updateSettings(context: context, settings: sdkSettings.value)
    }

    override func tearDown() {
        dispatchManager.stopDispatchLoop()
    }

    func test_launch_gets_dispatched_on_application_start_and_conatains_appData_collector_data() {
        let gotDispatched = expectation(description: "Launch has been dispatched")
        let eventContainsAppData = expectation(description: "Launch event contains app data")
        modulesManager.getModule(MockDispatcher.self)?.onDispatch.subscribeOnce { dispatches in
            let dispatch = dispatches[0]
            XCTAssertEqual(dispatch.name, "launch")
            gotDispatched.fulfill()
            XCTAssertNotNil(dispatch.payload.getDataItem(key: TealiumDataKey.appVersion))
            eventContainsAppData.fulfill()
        }
        waitForLongTimeout()
    }
}
