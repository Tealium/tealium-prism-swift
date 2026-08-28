//
//  DispatchManagerTestCase.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class DispatchManagerTestCase: XCTestCase {

    var allDispatchers: [String] {
        moduleManager.modules.value
            .filter { $0 is Dispatcher }
            .map { $0.id }
    }

    @StateSubject([
        TransformationSettings(id: "transformation1-aftercollectors",
                               transformerId: "transformer1",
                               scope: .afterCollectors),
        TransformationSettings(id: "transformation2-alldispatchers",
                               transformerId: "transformer1",
                               scope: .allDispatchers)
    ])
    var transformations

    let transformer = MockTransformer1 { transformation, dispatch, scope in
        var dispatch = dispatch
        dispatch.enrich(data: ["transformation-\(scope.rawValue)": transformation.id])
        return dispatch
    }
    lazy var transformers = StateSubject<[Transformer]>([transformer])
    lazy var onBarriers: Observable<[ScopedBarrier]> = Observables.just([(barrier, BarrierScope.all)])
    let barrier = MockBarrier()
    lazy var config = TealiumConfig(account: "test",
                                    profile: "test",
                                    environment: "dev",
                                    modules: [MockDispatcher1.factory(), MockDispatcher2.factory()],
                                    settingsFile: "",
                                    settingsUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var moduleManager = ModuleManager(queue: queue)
    lazy var _sdkSettings = StateSubject(SDKSettings(config.getEnforcedSDKSettings()))
    var sdkSettings: ObservableState<SDKSettings> {
        _sdkSettings.asObservableState()
    }
    var coreSettings: ObservableState<CoreSettings> {
        sdkSettings.mapState(transform: { $0.core })
    }
    lazy var queueManager = MockQueueManager(processors: TealiumImpl.queueProcessors(from: moduleManager.modules, addingConsent: true),
                                             queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                                 maxQueueSize: 10,
                                                                                 expiration: 1.days),
                                             coreSettings: coreSettings,
                                             logger: nil)
    let barrierManager = BarrierManager(sdkBarrierSettings: .constant([:]))
    lazy var barrierCoordinator = BarrierCoordinator(onScopedBarriers: onBarriers,
                                                     onApplicationStatus: config.appStatusListener.onApplicationStatus,
                                                     queueMetrics: queueManager,
                                                     flushDebounceMilliseconds: 0,
                                                     queue: .main)
    lazy var transformerCoordinator = TransformerCoordinator(transformers: transformers.asObservableState(),
                                                             transformations: transformations,
                                                             queue: .main,
                                                             logger: nil)
    lazy var context = MockContext(moduleManager: moduleManager,
                                   config: config,
                                   coreSettings: coreSettings,
                                   barrierRegistrar: barrierManager,
                                   transformerRegistrar: transformerCoordinator,
                                   databaseProvider: databaseProvider,
                                   queue: queue)
    var consentManager: MockConsentManager?
    lazy var dispatchManager = getDispatchManager()
    lazy var loadRuleEngine = LoadRuleEngine(sdkSettings: sdkSettings, logger: nil)
    lazy var mappingsEngine = MappingsEngine(mappings: sdkSettings
        .mapState { $0.modules.compactMapValues { $0.mappings } })

    func getDispatchManager() -> DispatchManager {
        DispatchManager(loadRuleEngine: loadRuleEngine,
                        moduleManager: moduleManager,
                        consentManager: consentManager,
                        queueManager: queueManager,
                        barrierCoordinator: barrierCoordinator,
                        transformerCoordinator: transformerCoordinator,
                        mappingsEngine: mappingsEngine,
                        logger: nil)
    }

    var module1: MockDispatcher1? {
        moduleManager.modules.value.compactMap { $0 as? MockDispatcher1 }.first
    }

    var module2: MockDispatcher2? {
        moduleManager.modules.value.compactMap { $0 as? MockDispatcher2 }.first
    }

    override func setUp() {
        super.setUp()
        moduleManager.updateSettings(context: context,
                                     settings: sdkSettings.value)
    }

    override func tearDown() {
        dispatchManager.stopDispatchLoop()
    }

    func disableModule<T: Module>(module: T?) {
        guard let module = module else { return }
        _sdkSettings.add(modules: [module.id: ModuleSettings(moduleId: module.id, moduleType: module.id, enabled: false)])
        moduleManager.updateSettings(context: context, settings: sdkSettings.value)
    }

    func enableModule(_ moduleType: String) {
        _sdkSettings.add(modules: [moduleType: ModuleSettings(moduleType: moduleType, enabled: true)])
        moduleManager.updateSettings(context: context, settings: sdkSettings.value)
    }
}
