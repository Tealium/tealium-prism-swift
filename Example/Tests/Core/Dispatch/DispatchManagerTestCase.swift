//
//  DispatchManagerTestCase.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class DispatchManagerTestCase: XCTestCase {

    var allDispatchers: [String] {
        modulesManager.modules.value
            .filter { $0 is Dispatcher }
            .map { $0.id }
    }

    @StateSubject([ScopedBarrier(barrierId: "barrier1", scopes: [.all])])
    var scopedBarriers: ObservableState<[ScopedBarrier]>

    @StateSubject([TransformationSettings(id: "transformation1", transformerId: "transformer1", scopes: [.afterCollectors, .allDispatchers])])
    var transformations: ObservableState<[TransformationSettings]>

    let transformer = MockTransformer1 { transformation, dispatch, scope in
        var dispatch = dispatch
        dispatch.enrich(data: ["transformation-\(scope)": transformation])
        return dispatch
    }
    lazy var transformers = StateSubject<[Transformer]>([transformer])
    let barrier = MockBarrier(id: "barrier1")
    let config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [MockDispatcher1.factory, MockDispatcher2.factory, MockConsentManager.factory],
                               settingsFile: "",
                               settingsUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var modulesManager = ModulesManager(queue: queue)
    lazy var settings: [String: DataObject] = [ConsentModule.id: ["enabled": false]] {
        didSet {
            sdkSettings.publish(SDKSettings(modules: settings))
        }
    }
    private(set) lazy var sdkSettings = StateSubject(SDKSettings(modules: settings))
    var coreSettings: ObservableState<CoreSettings> {
        sdkSettings.toStatefulObservable()
            .mapState(transform: { $0.core })
    }
    lazy var queueManager = MockQueueManager(processors: TealiumImpl.queueProcessors(from: modulesManager.modules),
                                             queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                                 maxQueueSize: 10,
                                                                                 expiration: TimeFrame(unit: .days, interval: 1)),
                                             coreSettings: coreSettings,
                                             logger: nil)
    lazy var barrierCoordinator = BarrierCoordinator(registeredBarriers: [barrier],
                                                     onScopedBarriers: scopedBarriers)
    lazy var transformerCoordinator = TransformerCoordinator(transformers: transformers.toStatefulObservable(),
                                                             transformations: transformations,
                                                             moduleMappings: StateSubject([:]).toStatefulObservable(),
                                                             queue: .main)
    lazy var context = TealiumContext(modulesManager: modulesManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: MockTracker(),
                                      barrierRegistry: barrierCoordinator,
                                      transformerRegistry: transformerCoordinator,
                                      databaseProvider: databaseProvider,
                                      moduleStoreProvider: ModuleStoreProvider(databaseProvider: databaseProvider,
                                                                               modulesRepository: MockModulesRepository()),
                                      logger: nil,
                                      networkHelper: MockNetworkHelper(),
                                      activityListener: ApplicationStatusListener.shared,
                                      queue: queue,
                                      visitorId: mockVisitorId)
    var consentManager: MockConsentManager? {
        modulesManager.getModule()
    }
    lazy var dispatchManager = getDispatchManager()
    lazy var loadRuleEngine = LoadRuleEngine(sdkSettings: sdkSettings.toStatefulObservable())
    func getDispatchManager() -> DispatchManager {
        DispatchManager(loadRuleEngine: loadRuleEngine,
                        modulesManager: modulesManager,
                        queueManager: queueManager,
                        barrierCoordinator: barrierCoordinator,
                        transformerCoordinator: transformerCoordinator,
                        logger: nil)
    }

    var module1: MockDispatcher1? {
        modulesManager.modules.value.compactMap { $0 as? MockDispatcher1 }.first
    }

    var module2: MockDispatcher2? {
        modulesManager.modules.value.compactMap { $0 as? MockDispatcher2 }.first
    }

    override func setUp() {
        super.setUp()
        modulesManager.updateSettings(context: context,
                                      settings: sdkSettings.value)
    }

    override func tearDown() {
        dispatchManager.stopDispatchLoop()
    }

    func disableModule<T: TealiumModule>(module: T?) {
        guard let module = module else { return }
        settings += [module.id: ["enabled": false]]
        modulesManager.updateSettings(context: context, settings: sdkSettings.value)
    }

    func enableModule(_ moduleId: String) {
        settings += [moduleId: ["enabled": true]]
        modulesManager.updateSettings(context: context, settings: sdkSettings.value)
    }
}
