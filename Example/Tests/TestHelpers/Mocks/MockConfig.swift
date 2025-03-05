//
//  MockConfig.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

let mockConfig = TealiumConfig(account: "mock_account",
                               profile: "mock_profile",
                               environment: "dev",
                               modules: [],
                               settingsFile: nil,
                               settingsUrl: nil)
private let mockDbProvider = MockDatabaseProvider()
private let queue = TealiumQueue.worker
let mockVisitorId = ObservableState(valueProvider: "visitorId", subscriptionHandler: { _ in Subscription(unsubscribe: {}) })
let mockContext = createContext(config: mockConfig, modulesManager: ModulesManager(queue: queue))
func createContext(config: TealiumConfig, modulesManager: ModulesManager) -> TealiumContext {
    TealiumContext(modulesManager: modulesManager,
                   config: config,
                   coreSettings: StateSubject(CoreSettings(coreDataObject: [:])).toStatefulObservable(),
                   tracker: MockTracker(),
                   barrierRegistry: BarrierCoordinator(registeredBarriers: [], onScopedBarriers: .Just([])),
                   transformerRegistry: TransformerCoordinator(transformers: StateSubject([]).toStatefulObservable(),
                                                               scopedTransformations: StateSubject([]).toStatefulObservable(),
                                                               queue: queue),
                   databaseProvider: mockDbProvider,
                   moduleStoreProvider: ModuleStoreProvider(databaseProvider: mockDbProvider,
                                                            modulesRepository: MockModulesRepository()),
                   logger: nil,
                   networkHelper: MockNetworkHelper(),
                   activityListener: ApplicationStatusListener.shared,
                   queue: queue,
                   visitorId: mockVisitorId)
}
