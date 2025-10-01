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
        config.modules = (config.modules + [
            Modules.dataLayer(),
            Modules.tealiumData()
        ]).removingDuplicates(by: \.moduleType)
    }

    static func addMandatoryAndRemoveDuplicateBarriers(from config: inout TealiumConfig) {
        config.barriers = (config.barriers + [
            Barriers.connectivity()
        ]).removingDuplicates(by: \.id)
    }

    static func initModuleStoreProvider(config: TealiumConfig) throws -> ModuleStoreProvider {
        let databaseProvider = try DatabaseProvider(config: config)
        return ModuleStoreProvider(databaseProvider: databaseProvider,
                                   modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
    }

    static func transformerCoordinator(transformers: ObservableState<[Transformer]>,
                                       sdkSettings: ObservableState<SDKSettings>,
                                       queue: TealiumQueue,
                                       logger: LoggerProtocol) -> TransformerCoordinator {
        let transformations = sdkSettings.mapState { $0.transformations.map { $0.value } }
        return TransformerCoordinator(transformers: transformers,
                                      transformations: transformations,
                                      queue: queue,
                                      logger: logger)
    }

    static func queueProcessors(from modules: ObservableState<[Module]>, addingConsent: Bool) -> Observable<[String]> {
        modules.filter { !$0.isEmpty }
            .map { modules in modules
                    .filter { $0 is Dispatcher }
                    .map { $0.id } + (addingConsent ? [ConsentIntegrationManager.id] : [])
            }.distinct()
    }
}
