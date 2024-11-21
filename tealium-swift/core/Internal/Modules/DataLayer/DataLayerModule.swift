//
//  DataLayerModule.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 28/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

class DataLayerModule: TealiumBasicModule {
    static var canBeDisabled: Bool { false }
    static let id: String = "DataLayer"
    let dataStore: DataStore

    convenience required init?(context: TealiumContext, moduleSettings: DataObject) {
        do {
            self.init(dataStore: try context.moduleStoreProvider.getModuleStore(name: Self.id))
        } catch {
            return nil
        }
    }

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    func put(data: DataObject, expiry: Expiry) {
        try? dataStore.edit()
            .putAll(dataObject: data, expiry: expiry)
            .commit()
    }

    func put(key: String, value: DataInput, expiry: Expiry) {
        try? dataStore.edit()
            .put(key: key, value: value, expiry: expiry)
            .commit()
    }

    func remove(key: String) {
        try? dataStore.edit()
            .remove(key: key)
            .commit()
    }

    func remove(keys: [String]) {
        try? dataStore.edit()
            .remove(keys: keys)
            .commit()
    }

    func clear() {
        try? dataStore.edit()
            .clear()
            .commit()
    }
}

extension DataLayerModule: Collector {
    var data: DataObject {
        dataStore.getAll()
    }
}

extension DataLayerModule: DataItemExtractor {
    func getDataItem(key: String) -> DataItem? {
        dataStore.getDataItem(key: key)
    }
}
