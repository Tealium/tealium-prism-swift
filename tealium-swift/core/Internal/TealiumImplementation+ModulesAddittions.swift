//
//  TealiumImplementation+ModulesAddittions.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumImpl {
    static func addMandatoryAndRemoveDuplicateModules(from config: inout TealiumConfig) {
        var moduleIdSet = Set<String>()
        let modules = (config.modules + [
            TealiumModules.dataLayer(),
            TealiumModules.tealiumCollector()
        ]).filter { moduleIdSet.insert($0.id).inserted }
        config.modules = modules
    }

    static func addMandatoryAndRemoveDuplicateBarriers(from config: inout TealiumConfig) {
        var barrierIdSet = Set<String>()
        let barriers = (config.barriers + [
            Barriers.connectivity()
        ]).filter { barrierIdSet.insert($0.id).inserted }
        config.barriers = barriers
    }

    static func initModuleStoreProvider(config: TealiumConfig) throws -> ModuleStoreProvider {
        let databaseProvider = try DatabaseProvider(config: config)
        return ModuleStoreProvider(databaseProvider: databaseProvider,
                                   modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))
    }
}
