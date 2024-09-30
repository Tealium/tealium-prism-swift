//
//  MockConfig.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

let mockConfig = TealiumConfig(account: "mock",
                               profile: "mock",
                               environment: "dev",
                               modules: [],
                               settingsFile: nil,
                               settingsUrl: nil)
private let mockDbProvider = MockDatabaseProvider()
private let queue = TealiumQueue.worker
let mockContext = TealiumContext(modulesManager: ModulesManager(queue: queue),
                                 config: mockConfig,
                                 coreSettings: StateSubject(CoreSettings(coreDataObject: [:])).toStatefulObservable(),
                                 tracker: MockTracker(),
                                 barrierRegistry: BarrierCoordinator(registeredBarriers: [], onScopedBarriers: .Just([])),
                                 transformerRegistry: TransformerCoordinator(registeredTransformers: [],
                                                                             scopedTransformations: StateSubject([]).toStatefulObservable(),
                                                                             queue: queue),
                                 databaseProvider: mockDbProvider,
                                 moduleStoreProvider: ModuleStoreProvider(databaseProvider: mockDbProvider,
                                                                          modulesRepository: MockModulesRepository()),
                                 logger: nil,
                                 networkHelper: MockNetworkHelper(),
                                 activityListener: ApplicationStatusListener.shared,
                                 queue: queue)
