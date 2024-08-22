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
let mockContext = TealiumContext(modulesManager: ModulesManager(),
                                 config: mockConfig,
                                 coreSettings: StateSubject(CoreSettings(coreDictionary: [:])).toStatefulObservable(),
                                 tracker: MockTracker(),
                                 barrierRegistry: BarrierCoordinator(registeredBarriers: [], onScopedBarriers: .Just([])),
                                 transformerRegistry: TransformerCoordinator(registeredTransformers: [], scopedTransformations: StateSubject([]).toStatefulObservable()),
                                 databaseProvider: mockDbProvider,
                                 moduleStoreProvider: ModuleStoreProvider(databaseProvider: mockDbProvider, modulesRepository: MockModulesRepository()),
                                 logger: nil,
                                 networkHelper: MockNetworkHelper(),
                                 activityListener: ApplicationStatusListener.shared)
