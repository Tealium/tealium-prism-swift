//
//  SQLModulesRepository.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

class SQLModulesRepository: ModulesRepository {

    @ToAnyObservable<BasePublisher<ExpiredDataEvent>>(BasePublisher<ExpiredDataEvent>())
    var onDataExpired: Observable<ExpiredDataEvent>
    private let database: Connection

    init(dbProvider: DatabaseProviderProtocol) {
        self.database = dbProvider.database
    }

    func getModules() -> [String: Int64] {
        guard let rows = try? database.prepare(ModuleSchema.getModules()) else {
            return [:]
        }
        return [String: Int64](rows.compactMap({ row in
            return (row[ModuleSchema.name], row[ModuleSchema.id])
        }), uniquingKeysWith: { _, second in second })
    }

    func registerModule(name: String) throws -> Int64 {
        if let moduleRow = try database.pluck(ModuleSchema.getModule(moduleName: name)) {
            return moduleRow[ModuleSchema.id]
        }
        return try database.run(ModuleSchema.createModule(moduleName: name))
    }

    func deleteExpired(expiry: ExpirationRequest) {
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
