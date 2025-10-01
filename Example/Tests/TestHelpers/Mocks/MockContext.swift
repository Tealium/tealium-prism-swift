//
//  MockContext.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 06/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism

private let mockDbProvider = MockDatabaseProvider()
private let queue = TealiumQueue.worker
private let mockVisitorId = ObservableState(valueProvider: "visitorId", subscriptionHandler: { _ in Subscription(unsubscribe: {}) })
let mockContext = MockContext(modulesManager: ModulesManager(queue: queue), config: mockConfig)

class MockContext: TealiumContext {
    init(modulesManager: ModulesManager,
         sessionRegistry: SessionRegistry? = nil,
         config: TealiumConfig = mockConfig,
         coreSettings: ObservableState<CoreSettings> = .constant(CoreSettings()),
         tracker: Tracker = MockTracker(),
         barrierRegistry: BarrierRegistry = BarrierManager(sdkBarrierSettings: .constant([:])),
         transformerRegistry: TransformerRegistry? = nil,
         databaseProvider: DatabaseProviderProtocol = mockDbProvider,
         logger: LoggerProtocol? = nil,
         networkHelper: NetworkHelperProtocol = MockNetworkHelper(),
         activityListener: ApplicationStatusListener = ApplicationStatusListener.shared,
         queue: TealiumQueue = TealiumQueue.worker,
         visitorId: ObservableState<String> = mockVisitorId) {
        let transformerRegistry = transformerRegistry ?? TransformerCoordinator(
            transformers: .constant([]),
            transformations: .constant([]),
            queue: queue,
            logger: nil
        )
        let queueManager = MockQueueManager(
            processors: TealiumImpl.queueProcessors(from: modulesManager.modules, addingConsent: true),
            queueRepository: SQLQueueRepository(dbProvider: databaseProvider,
                                                maxQueueSize: 10,
                                                expiration: 1.days),
            coreSettings: coreSettings,
            logger: nil
        )
        super.init(modulesManager: modulesManager,
                   sessionRegistry: MockSessionManager(databaseProvider: databaseProvider),
                   config: config,
                   coreSettings: coreSettings,
                   tracker: tracker,
                   barrierRegistry: barrierRegistry,
                   transformerRegistry: transformerRegistry,
                   databaseProvider: databaseProvider,
                   moduleStoreProvider: ModuleStoreProvider(
                    databaseProvider: databaseProvider,
                    modulesRepository: SQLModulesRepository(dbProvider: databaseProvider)
                   ),
                   logger: logger,
                   networkHelper: networkHelper,
                   activityListener: activityListener,
                   queue: queue,
                   visitorId: visitorId,
                   queueMetrics: queueManager)
    }
}
