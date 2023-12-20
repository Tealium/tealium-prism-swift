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
    @TealiumMutableState([ScopedBarrier(barrierId: "barrier1", scopes: [.all])])
    var scopedBarriers: TealiumObservableState<[ScopedBarrier]>

    @TealiumMutableState([ScopedTransformation(id: "transformation1", transformerId: "transformer1", scopes: [.afterCollectors, .allDispatchers])])
    var scopedTransformations: TealiumObservableState<[ScopedTransformation]>

    let transformer = MockTransformer(id: "transformer1") { transformation, dispatch, scope in
        var dispatch = dispatch
        dispatch.enrich(data: ["transformation-\(scope)": transformation])
        return dispatch

    }
    let barrier = MockBarrier(id: "barrier1")
    let config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [MockDispatcher1.self, MockDispatcher2.self],
                               configFile: "",
                               configUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let modulesManager = ModulesManager()
    @TealiumMutableState(CoreSettings(coreDictionary: [:]))
    var coreSettings: TealiumObservableState<CoreSettings>
    lazy var queueManager = MockQueueManager(modulesManager: modulesManager)
    lazy var context = TealiumContext(modulesManager: modulesManager,
                                      config: config,
                                      coreSettings: coreSettings,
                                      tracker: MockTracker(),
                                      databaseProvider: databaseProvider,
                                      moduleStoreProvider: ModuleStoreProvider(databaseProvider: databaseProvider,
                                                                               modulesRepository: MockModulesRepository()),
                                      logger: nil,
                                      networkHelper: MockNetworkHelper())
    let consentManager = MockConsentManager()
    lazy var dispatchManager = getDispatchManager()
    func getDispatchManager() -> DispatchManager {
        DispatchManager(modulesManager: modulesManager,
                        consentManager: consentManager,
                        queueManager: queueManager,
                        barrierCoordinator: BarrierCoordinator(registeredBarriers: [barrier],
                                                               onScopedBarriers: $scopedBarriers),
                        transformerCoordinator: TransformerCoordinator(registeredTransformers: [transformer],
                                                                       scopedTransformations: scopedTransformations,
                                                                       queue: .main))
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
                                      settings: [:])
    }

    func disableModule(module: MockDispatcher?) {
        guard let module = module else { return }
        modulesManager.updateSettings(context: context, settings: [module.id: ["enabled": false]])
    }
}
