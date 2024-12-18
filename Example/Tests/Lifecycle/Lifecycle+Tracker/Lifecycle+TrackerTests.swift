//
//  Lifecycle+TrackerTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 10/12/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class LifecycleTrackerTests: XCTestCase {
    @StateSubject([ScopedBarrier(barrierId: "barrier1", scopes: [.all])])
    var scopedBarriers: ObservableState<[ScopedBarrier]>

    @StateSubject([ScopedTransformation(id: "transformation1", transformerId: "transformer1", scopes: [.afterCollectors, .allDispatchers])])
    var scopedTransformations: ObservableState<[ScopedTransformation]>
    let config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [
                                MockDispatcher.factory,
                                MockConsentManager.factory,
                                TealiumModules.lifecycle(forcingSettings: { enforcedSettings in
                                    enforcedSettings.setEnabled(true)
                                }),
                                TealiumModules.appData()
                               ],
                               settingsFile: "",
                               settingsUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var modulesManager = ModulesManager(queue: queue)
    lazy var settings: [String: DataObject] = [ConsentModule.id: ["enabled": false]]
    var sdkSettings: SDKSettings {
        SDKSettings(modulesSettings: settings)
    }
    lazy var _coreSettings = StateSubject(CoreSettings(coreDataObject: settings[CoreSettings.id] ?? [:]))
    var coreSettings: ObservableState<CoreSettings> {
        _coreSettings.toStatefulObservable()
    }
    lazy var queueManager = MockQueueManager(processors: TealiumImpl.queueProcessors(from: modulesManager.modules),
                                             queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                                 maxQueueSize: 10,
                                                                                 expiration: TimeFrame(unit: .days, interval: 1)),
                                             coreSettings: coreSettings,
                                             logger: nil)
    lazy var barrierCoordinator = BarrierCoordinator(registeredBarriers: [],
                                                     onScopedBarriers: scopedBarriers)
    lazy var transformerCoordinator = TransformerCoordinator(registeredTransformers: [],
                                                             scopedTransformations: scopedTransformations,
                                                             queue: .main)
    lazy var tracker = TealiumTracker(modulesManager: modulesManager, dispatchManager: dispatchManager, logger: nil)
    lazy var context = TealiumContext(modulesManager: modulesManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: tracker,
                                      barrierRegistry: barrierCoordinator,
                                      transformerRegistry: transformerCoordinator,
                                      databaseProvider: databaseProvider,
                                      moduleStoreProvider: ModuleStoreProvider(databaseProvider: databaseProvider,
                                                                               modulesRepository: SQLModulesRepository(dbProvider: databaseProvider)),
                                      logger: nil,
                                      networkHelper: MockNetworkHelper(),
                                      activityListener: ApplicationStatusListener.shared,
                                      queue: queue,
                                      visitorId: mockVisitorId)
    var consentManager: MockConsentManager? {
        modulesManager.getModule()
    }
    lazy var dispatchManager = getDispatchManager()
    func getDispatchManager() -> DispatchManager {
        DispatchManager(modulesManager: modulesManager,
                        queueManager: queueManager,
                        barrierCoordinator: barrierCoordinator,
                        transformerCoordinator: transformerCoordinator,
                        logger: nil)
    }

    override func setUp() {
        super.setUp()
        modulesManager.updateSettings(context: context, settings: sdkSettings)
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
            XCTAssertNotNil(dispatch.eventData.getDataItem(key: TealiumDataKey.appVersion))
            eventContainsAppData.fulfill()
        }
        waitForLongTimeout()
    }
}
