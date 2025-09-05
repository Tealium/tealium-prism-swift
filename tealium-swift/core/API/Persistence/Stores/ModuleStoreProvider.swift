//
//  ModuleStoreProvider.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A class responsible for registering and returning the DataStore instances required by individual modules.
 */
public class ModuleStoreProvider {
    let databaseProvider: DatabaseProviderProtocol
    let modulesRepository: ModulesRepository
    var stores = [Int64: DataStore]()

    init(databaseProvider: DatabaseProviderProtocol, modulesRepository: ModulesRepository) {
        self.databaseProvider = databaseProvider
        self.modulesRepository = modulesRepository
    }

    /**
     * Registers a module for storage and returns its `DataStore` object, which can be used to read/write data.
     *
     * - parameter name: The module name whose `DataStore` is required.
     */
    public func getModuleStore(name: String) throws -> DataStore {
        let moduleId = try modulesRepository.registerModule(name: name)
        if let cached = stores[moduleId] {
            return cached
        }
        let newStore = try createStore(moduleId: moduleId)
        stores[moduleId] = newStore
        return newStore
    }

    private func createStore(moduleId: Int64) throws -> DataStore {
        ModuleStore(repository: SQLKeyValueRepository(dbProvider: databaseProvider, moduleId: moduleId),
                    onDataExpired: modulesRepository.onDataExpired.compactMap { dataExpiredEvent in dataExpiredEvent[moduleId] })
    }
}
