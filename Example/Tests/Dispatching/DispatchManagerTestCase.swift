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

    @TealiumVariableSubject([ScopedBarrier(barrierId: "barrier1", scopes: [.all])])
    var scopedBarriers: TealiumStatefulObservable<[ScopedBarrier]>

    @TealiumVariableSubject([ScopedTransformation(id: "transformation1", transformerId: "transformer1", scopes: [.afterCollectors, .allDispatchers])])
    var scopedTransformations: TealiumStatefulObservable<[ScopedTransformation]>

    let transformer = MockTransformer(id: "transformer1") { transformation, dispatch, scope in
        var dispatch = dispatch
        dispatch.enrich(data: ["transformation-\(scope)": transformation])
        return dispatch

    }
    let barrier = MockBarrier(id: "barrier1")
    let config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [MockDispatcher1.self, MockDispatcher2.self, MockConsentManager.self],
                               configFile: "",
                               configUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let modulesManager = ModulesManager()
    lazy var settings: [String: Any] = ["consent": ["enabled": false]]
    lazy var _coreSettings = TealiumVariableSubject(CoreSettings(coreDictionary: settings))
    var coreSettings: TealiumStatefulObservable<CoreSettings> {
        _coreSettings.toStatefulObservable()
    }
    lazy var queueManager = MockQueueManager(processors: TealiumImplementation.queueProcessors(from: modulesManager.modules),
                                             queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                                                 maxQueueSize: 10,
                                                                                 expiration: TimeFrame(unit: .days, interval: 1)),
                                             coreSettings: coreSettings)
    lazy var barrierCoordinator = BarrierCoordinator(registeredBarriers: [barrier],
                                                     onScopedBarriers: scopedBarriers)
    lazy var transformerCoordinator = TransformerCoordinator(registeredTransformers: [transformer],
                                                             scopedTransformations: scopedTransformations,
                                                             queue: .main)
    lazy var context = TealiumContext(modulesManager: modulesManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: MockTracker(),
                                      queueManager: queueManager,
                                      barrierRegistry: barrierCoordinator,
                                      transformerRegistry: transformerCoordinator,
                                      databaseProvider: databaseProvider,
                                      moduleStoreProvider: ModuleStoreProvider(databaseProvider: databaseProvider,
                                                                               modulesRepository: MockModulesRepository()),
                                      logger: nil,
                                      networkHelper: MockNetworkHelper())
    var consentManager: MockConsentManager? {
        modulesManager.getModule()
    }
    lazy var dispatchManager = getDispatchManager()
    func getDispatchManager() -> DispatchManager {
        DispatchManager(modulesManager: modulesManager,
                        queueManager: queueManager,
                        barrierCoordinator: barrierCoordinator,
                        transformerCoordinator: transformerCoordinator)
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
                                      settings: settings)
    }

    override func tearDown() {
        dispatchManager.stopDispatchLoop()
    }

    func disableModule<T: TealiumModule>(module: T?) {
        guard let module = module else { return }
        settings += [module.id: ["enabled": false]]
        modulesManager.updateSettings(context: context, settings: settings)
    }

    func enableModule(_ moduleId: String) {
        settings += [moduleId: ["enabled": true]]
        modulesManager.updateSettings(context: context, settings: settings)
    }
}
