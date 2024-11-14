//
//  DataLayerModule.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 28/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

class DataLayerModule: TealiumBasicModule, Collector, DataItemExtractor {
    static var canBeDisabled: Bool { false }
    var data: DataObject {
        moduleStore.getAll()
    }
    static let id: String = "DataLayer"
    let moduleStore: DataStore

    required init?(context: TealiumContext, moduleSettings: DataObject) {
        do {
            moduleStore = try context.moduleStoreProvider.getModuleStore(name: Self.id)
        } catch {
            return nil
        }
    }

    func put(data: DataObject, expiry: Expiry = .session) {
        try? moduleStore.edit()
            .putAll(dataObject: data, expiry: expiry)
            .commit()
    }
    func put(key: String, value: DataInput, expiry: Expiry = .session) {
        try? moduleStore.edit()
            .put(key: key, value: value, expiry: expiry)
            .commit()
    }
    func remove(key: String) {
        try? moduleStore.edit()
            .remove(key: key)
            .commit()
    }
    func removeAll() {
        try? moduleStore.edit()
            .clear()
            .commit()
    }
    func remove(keys: [String]) {
        try? moduleStore.edit()
            .remove(keys: keys)
            .commit()
    }
    func getDataItem(key: String) -> DataItem? {
        moduleStore.getDataItem(key: key)
    }
}
