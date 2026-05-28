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
    private let database: Connection
    private let signposter = TealiumSignposter(category: "Modules-Repository")
    init(dbProvider: DatabaseProviderProtocol) {
        self.database = dbProvider.database
    }

    func getModules() -> [String: Int64] {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Get Modules").begin()
        defer { interval.end() }
        guard let rows = try? database.prepare(ModuleSchema.getModules()) else {
            return [:]
        }
        return [String: Int64](rows.map { row in
            (row[ModuleSchema.name], row[ModuleSchema.id])
        }, prefersFirst: false)
    }

    func registerModule(name: String) throws -> Int64 {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Register Module").begin(name)
        defer { interval.end() }
        if let moduleRow = try database.pluck(ModuleSchema.getModule(moduleName: name)) {
            return moduleRow[ModuleSchema.id]
        }
        return try database.run(ModuleSchema.createModule(moduleName: name))
    }

    func deleteExpired(expiry: ExpirationRequest) {
        let interval = TealiumSignpostInterval(signposter: signposter, name: "Delete Expired").begin("\(expiry)")
        defer { interval.end() }
        let date = Date()
        guard let rows = try? database.prepare(ModuleStorageSchema.getExpired(request: expiry, date: date)) else {
            return
        }
        let dataExpired = rows.reduce(ExpiredDataEvent()) { result, row in
            var result = result
            var moduleData = result[row[ModuleStorageSchema.moduleId]] ?? [String: DataItem]()
            moduleData[row[ModuleStorageSchema.key]] = DataItem(stringValue: row[ModuleStorageSchema.value])
            result[row[ModuleStorageSchema.moduleId]] = moduleData
            return result
        }
        if !dataExpired.isEmpty {
            _ = try? database.run(ModuleStorageSchema.deleteExpired(request: expiry, date: date))
            _onDataExpired.publish(dataExpired)
        }
    }
}
