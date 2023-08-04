//
//  DataLayerStorage.swift
//  tealium-swift
//
//  Created by Tyler Rister on 31/5/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

public struct Transaction {
    var transactionSteps: [any ExpressionType] = []
}

public class TransactionEditor {
    var transaction = Transaction()
    let moduleStorage: ModuleStorage

    init(moduleStorage: ModuleStorage) {
        self.moduleStorage = moduleStorage
    }
    public func add(key: String, value: TealiumDataValue, expiry: Expiry = Expiry.session) throws -> TransactionEditor {
        self.transaction.transactionSteps.append(
            ModuleStorageSchema.insertOrReplace(moduleId: moduleStorage.moduleId,
                                                key: key,
                                                value: try value.serialize(),
                                                expiry: expiry))
        return self
    }
    public func addAll(values: TealiumDictionary, expiry: Expiry = Expiry.session) throws -> TransactionEditor {
        for value in values {
            _ = try add(key: value.key, value: value.value, expiry: expiry)
        }
        return self
    }
    public func remove(key: String) -> TransactionEditor {
        self.transaction.transactionSteps.append(
            ModuleStorageSchema.delete(key: key,
                                       moduleId: moduleStorage.moduleId))
        return self
    }

    public func removeAll(keys: [String]) -> TransactionEditor {
        keys.forEach { key in
            _ = remove(key: key)
        }
        return self
    }

    public func commit() throws {
        try moduleStorage.commit(transaction: transaction)
    }
}

public class ModuleStorage {
    let database: Connection?
    let moduleName: String
    private(set) var moduleId: Int = 0

    public init(database: Connection?, moduleName: String) throws {
        self.database = database
        self.moduleName = moduleName
        try moduleId = getOrCreateModule()
    }

    func getOrCreateModule() throws -> Int {
        guard let database = self.database else {
            throw DatabaseErrors.databaseNil
        }
        if let module = try? database.pluck(ModuleSchema.getModule(moduleName: moduleName)) {
            return Int(module[ModuleSchema.id])
        }
        if let newModule = try? database.run(ModuleSchema.createModule(moduleName: moduleName)) {
            return Int(newModule)
        }
        throw DatabaseErrors.moduleIdCreationFailed
    }

    public func edit() -> TransactionEditor {
        return TransactionEditor(moduleStorage: self)
    }

    public func commit(transaction: Transaction) throws {
        guard let database = self.database else {
            return
        }
        try database.transaction {
            for step in transaction.transactionSteps {
                _ = try database.run(step.template, step.bindings)
            }
        }
    }

    public func get(key: String) -> Any? {
        guard let database = self.database,
              let row = try? database.pluck(ModuleStorageSchema.getValue(key: key, moduleId: self.moduleId)),
              let value = try? row[ModuleStorageSchema.value].deserialize() else {
            return nil
        }
        let expiry = Expiry.fromValue(value: row[ModuleStorageSchema.expiry])
        return expiry.isExpired() ? nil : value
    }

    public func getAll() -> [String: Any] {
        guard let database = self.database,
              let rows = try? database.prepare(ModuleStorageSchema.getAllRows(moduleId: moduleId)) else {
            return [:]
        }
        var dictionary = [String: Any]()
        for row in rows {
            if let value = try? row[ModuleStorageSchema.value].deserialize() {
                let expiry = Expiry.fromValue(value: row[ModuleStorageSchema.expiry])
                if !expiry.isExpired() {
                    dictionary[row[ModuleStorageSchema.key]] = value
                }
            }
        }
        return dictionary
    }

    public func getInt(key: String) -> Int64? {
        guard let value = get(key: key) as? NSNumber else {
            return nil
        }
        return Int64(truncating: value)
    }

    public func getString(key: String) -> String? {
        return get(key: key) as? String
    }

    public func getDouble(key: String) -> Double? {
        return get(key: key) as? Double
    }

    public func getBool(key: String) -> Bool? {
        return get(key: key) as? Bool
    }

    public func getArray(key: String) -> [Any]? {
        return get(key: key) as? [Any]
    }

    public func getDictionary(key: String) -> [String: Any]? {
        return get(key: key) as? [String: Any]
    }

    public func keys() -> [String] {
        guard let database = self.database,
              let mapRowIterator = try? database.prepareRowIterator(ModuleStorageSchema.getKeys(moduleId: moduleId)),
              let keys = try? mapRowIterator.map({ $0[ModuleStorageSchema.key] }) else {
            return []
        }
        return keys
    }

    public func count() -> Int {
        guard let database = self.database,
              let count = try? database.scalar(ModuleStorageSchema.getCount(moduleId: moduleId)) else {
            return 0
        }
        return count
    }
}
