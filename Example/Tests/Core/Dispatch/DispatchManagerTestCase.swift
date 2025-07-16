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

    @StateSubject([TransformationSettings(id: "transformation1", transformerId: "transformer1", scopes: [.afterCollectors, .allDispatchers])])
    var transformations: ObservableState<[TransformationSettings]>

    let transformer = MockTransformer1 { transformation, dispatch, scope in
        var dispatch = dispatch
        dispatch.enrich(data: ["transformation-\(scope)": transformation])
        return dispatch
    }
    lazy var transformers = StateSubject<[Transformer]>([transformer])
    lazy var onBarriers = Observable<[ScopedBarrier]>.Just([(barrier, [BarrierScope.all])])
    let barrier = MockBarrier()
    let config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [MockDispatcher1.factory, MockDispatcher2.factory],
                               settingsFile: "",
                               settingsUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var modulesManager = ModulesManager(queue: queue)
    var _sdkSettings = StateSubject(SDKSettings())
    var sdkSettings: ObservableState<SDKSettings> {
        _sdkSettings.toStatefulObservable()
    }
    var coreSettings: ObservableState<CoreSettings> {
        sdkSettings.mapState(transform: { $0.core })
    }
    lazy var queueManager = MockQueueManager(processors: TealiumImpl.queueProcessors(from: modulesManager.modules, addingConsent: true),
                                             queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                                 maxQueueSize: 10,
                                                                                 expiration: TimeFrame(unit: .days, interval: 1)),
                                             coreSettings: coreSettings,
                                             logger: nil)
    let barrierManager = BarrierManager(sdkBarrierSettings: .constant([:]))
    lazy var barrierCoordinator = BarrierCoordinator(onScopedBarriers: onBarriers,
                                                     onApplicationStatus: ApplicationStatusListener.shared.onApplicationStatus,
                                                     queueMetrics: queueManager)
    lazy var transformerCoordinator = TransformerCoordinator(transformers: transformers.toStatefulObservable(),
                                                             transformations: transformations,
                                                             moduleMappings: .constant([:]),
                                                             queue: .main)
    lazy var context = MockContext(modulesManager: modulesManager,
                                   config: config,
                                   coreSettings: coreSettings,
                                   barrierRegistry: barrierManager,
                                   transformerRegistry: transformerCoordinator,
                                   databaseProvider: databaseProvider,
                                   queue: queue)
    var consentManager: MockConsentManager?
    lazy var dispatchManager = getDispatchManager()
    lazy var loadRuleEngine = LoadRuleEngine(sdkSettings: sdkSettings)
    lazy var mappingsEngine = MappingsEngine(mappings: sdkSettings
        .mapState { $0.modules.compactMapValues { $0.mappings } })

    func getDispatchManager() -> DispatchManager {
        DispatchManager(loadRuleEngine: loadRuleEngine,
                        modulesManager: modulesManager,
                        consentManager: consentManager,
                        queueManager: queueManager,
                        barrierCoordinator: barrierCoordinator,
                        transformerCoordinator: transformerCoordinator,
                        mappingsEngine: mappingsEngine,
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
        _sdkSettings.add(modules: [module.id: ModuleSettings(enabled: false)])
        modulesManager.updateSettings(context: context, settings: sdkSettings.value)
    }

    func enableModule(_ moduleId: String) {
        _sdkSettings.add(modules: [moduleId: ModuleSettings(enabled: true)])
        modulesManager.updateSettings(context: context, settings: sdkSettings.value)
    }
}
