//
//  TealiumImpl+Statics.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumImpl {
    static func addMandatoryAndRemoveDuplicateModules(from config: inout TealiumConfig) {
        config.modules = (config.modules + ModuleRegistry.shared.defaultModules )
            .removingDuplicates(by: \.moduleType)
    }

    static func addMandatoryAndRemoveDuplicateBarriers(from config: inout TealiumConfig) {
        config.barriers = (config.barriers + BarrierRegistry.shared.defaultBarriers)
            .removingDuplicates(by: \.id)
    }

    static func initModuleStoreProvider(config: TealiumConfig) throws -> ModuleStoreProvider {
        let databaseProvider = try DatabaseProvider(config: config)
        return ModuleStoreProvider(databaseProvider: databaseProvider,
                                   modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
    }

    static func transformerCoordinator(onTransformers: Observable<[Transformer]>,
                                       sdkSettings: ObservableState<SDKSettings>,
                                       queue: TealiumQueue,
                                       logger: LoggerProtocol) -> TransformerCoordinator {
        let transformations = sdkSettings.mapState { $0.transformations.map { $0.value } }
        return TransformerCoordinator(onTransformers: onTransformers,
                                      transformations: transformations,
                                      queue: queue,
                                      logger: logger)
    }

    /**
     * The ids of the queues the dispatches have to be stored for.
     */
    static func queueProcessors(from onDispatchers: Observable<[Dispatcher]>, addingConsent: Bool) -> Observable<[String]> {
        onDispatchers
            .map { dispatchers in
                dispatchers.map { $0.id } + (addingConsent ? [ConsentIntegrationManager.id] : [])
            }.distinct()
    }
}
