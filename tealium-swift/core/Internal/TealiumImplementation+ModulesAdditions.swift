//
//  TealiumImplementation+ModulesAdditions.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumImpl {
    static func addMandatoryAndRemoveDuplicateModules(from config: inout TealiumConfig) {
        config.modules = (config.modules + [
            Modules.dataLayer(),
            Modules.tealiumCollector()
        ]).removingDuplicates(by: \.id)
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
}
