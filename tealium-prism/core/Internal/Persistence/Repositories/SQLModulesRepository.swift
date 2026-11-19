//
//  SQLModulesRepository.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

class SQLModulesRepository: ModulesRepository {

    @Subject<ExpiredDataEvent> var onDataExpired
    private let database: DatabaseConnection
    private let signposter = TealiumSignposter(category: "Modules-Repository")
    init(dbProvider: DatabaseProviderProtocol) {
        self.database = dbProvider.database
    }

    func getModules() -> [String: Int64] {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Get Modules").begin()
        defer { interval.end() }
        guard let modules = try? database.rows(ModuleSchema.getModules())
            .map({ row in
                (try row.get(ModuleSchema.name), try row.get(ModuleSchema.id))
            }) else {
            return [:]
        }
        return [String: Int64](modules, prefersFirst: false)
    }

    func registerModule(name: String) throws -> Int64 {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Register Module").begin(name)
        defer { interval.end() }
        if let moduleRow = try database.pluck(ModuleSchema.getModule(moduleName: name)) {
            return try moduleRow.get(ModuleSchema.id)
        }
        return try database.run(ModuleSchema.createModule(moduleName: name))
    }

    func deleteExpired(expiry: ExpirationRequest) {
        deleteExpired(expiry: expiry, date: Date())
    }

    /// Deletes the data matching `expiry` or whose time-based expiry has passed at `date`.
    func deleteExpired(expiry: ExpirationRequest, date: Date) {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Delete Expired").begin("\(expiry)")
        defer { interval.end() }
        guard let expired = try? database.rows(ModuleStorageSchema.getExpired(request: expiry, date: date))
            .map({ row in
                (moduleId: try row.get(ModuleStorageSchema.moduleId),
                 key: try row.get(ModuleStorageSchema.key),
                 value: try row.get(ModuleStorageSchema.value))
            }) else {
            return
        }
        let dataExpired = expired.reduce(ExpiredDataEvent()) { result, row in
            var result = result
            var moduleData = result[row.moduleId] ?? [String: DataItem]()
            moduleData[row.key] = DataItem(stringValue: row.value)
            result[row.moduleId] = moduleData
            return result
        }
        if !dataExpired.isEmpty {
            _ = try? database.run(ModuleStorageSchema.deleteExpired(request: expiry, date: date))
            _onDataExpired.onNext(dataExpired)
        }
    }
}
