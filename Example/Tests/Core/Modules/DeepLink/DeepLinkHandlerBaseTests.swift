//
//  DeepLinkHandlerBaseTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 17/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class DeepLinkHandlerBaseTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let tracker = MockTracker()
    lazy var manager = ModulesManager(queue: queue)
    lazy var onManager: ReplaySubject<ModulesManager?> = ReplaySubject(initialValue: manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var wrapper = TraceManagerWrapper(moduleProxy: ModuleProxy(onModulesManager: onManager.asObservable()))
    @StateSubject(CoreSettings())
    var coreSettings
    func context() -> TealiumContext {
        TealiumContext(modulesManager: manager,
                       config: config,
                       coreSettings: coreSettings,
                       tracker: tracker,
                       barrierRegistry: BarrierManager(sdkBarrierSettings: StateSubject([:]).toStatefulObservable()),
                       transformerRegistry: TransformerCoordinator(transformers: StateSubject([]).toStatefulObservable(),
                                                                   transformations: StateSubject([]).toStatefulObservable(),
                                                                   moduleMappings: StateSubject([:]).toStatefulObservable(),
                                                                   queue: queue),
                       databaseProvider: dbProvider,
                       moduleStoreProvider: ModuleStoreProvider(databaseProvider: dbProvider,
                                                                modulesRepository: SQLModulesRepository(dbProvider: dbProvider)),
                       logger: nil,
                       networkHelper: MockNetworkHelper(),
                       activityListener: ApplicationStatusListener.shared,
                       queue: queue,
                       visitorId: mockVisitorId)
    }
    var deepLink: DeepLinkHandlerModule!
    let dispatchContext = DispatchContext(source: .application, initialData: [:])
    let testTraceId = "testTraceId"

    override func setUpWithError() throws {
        config.modules = [TealiumModules.trace()]
        let context = context()
        manager.updateSettings(context: context, settings: SDKSettings([:]))
        deepLink = DeepLinkHandlerModule(context: context, moduleConfiguration: [:])
    }

    func updateSettings(_ builder: DeepLinkSettingsBuilder) {
        let configuration = builder.build()
            .getDataDictionary(key: "configuration")?.toDataObject() ?? [:]
        _ = deepLink.updateConfiguration(configuration)
    }
}
