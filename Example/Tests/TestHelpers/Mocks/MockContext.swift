//
//  MockContext.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift

private let mockDbProvider = MockDatabaseProvider()
private let queue = TealiumQueue.worker
private let mockVisitorId = ObservableState(valueProvider: "visitorId", subscriptionHandler: { _ in Subscription(unsubscribe: {}) })
let mockContext = MockContext(modulesManager: ModulesManager(queue: queue), config: mockConfig)

class MockContext: TealiumContext {
    init(modulesManager: ModulesManager,
         config: TealiumConfig = mockConfig,
         coreSettings: ObservableState<CoreSettings> = StateSubject(CoreSettings()).toStatefulObservable(),
         tracker: Tracker = MockTracker(),
         barrierRegistry: BarrierRegistry = BarrierManager(sdkBarrierSettings: StateSubject([:]).toStatefulObservable()),
         transformerRegistry: TransformerRegistry? = nil,
         databaseProvider: DatabaseProviderProtocol = mockDbProvider,
         logger: LoggerProtocol? = nil,
         networkHelper: NetworkHelperProtocol = MockNetworkHelper(),
         activityListener: ApplicationStatusListener = ApplicationStatusListener.shared,
         queue: TealiumQueue = TealiumQueue.worker,
         visitorId: ObservableState<String> = mockVisitorId) {
        let transformerRegistry = transformerRegistry ?? TransformerCoordinator(transformers: StateSubject([]).toStatefulObservable(),
                                                                                transformations: StateSubject([]).toStatefulObservable(),
                                                                                moduleMappings: StateSubject([:]).toStatefulObservable(),
                                                                                queue: queue)
        super.init(modulesManager: modulesManager,
                   config: config,
                   coreSettings: coreSettings,
                   tracker: tracker,
                   barrierRegistry: barrierRegistry,
                   transformerRegistry: transformerRegistry,
                   databaseProvider: databaseProvider,
                   moduleStoreProvider: ModuleStoreProvider(databaseProvider: databaseProvider,
                                                            modulesRepository: SQLModulesRepository(dbProvider: databaseProvider)),
                   logger: logger,
                   networkHelper: networkHelper,
                   activityListener: activityListener,
                   queue: queue,
                   visitorId: visitorId)
    }
}
