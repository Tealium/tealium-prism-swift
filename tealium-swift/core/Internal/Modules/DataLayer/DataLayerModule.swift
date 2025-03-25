//
//  DataLayerModule.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 28/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

class DataLayerModule: TealiumBasicModule {
    var version: String = TealiumConstants.libraryVersion
    static var canBeDisabled: Bool { false }
    static let id: String = "DataLayer"
    let dataStore: DataStore

    convenience required init?(context: TealiumContext, moduleConfiguration: DataObject) {
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

    // the difference between this method and collect(): this one is for arbitrary request for data, not in collection phase
    func getAll() -> DataObject {
        dataStore.getAll()
    }
}

// MARK: Collector
extension DataLayerModule: Collector {
    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        dataStore.getAll()
    }
}

// MARK: DataItemExtractor
extension DataLayerModule: DataItemExtractor {
    func getDataItem(key: String) -> DataItem? {
        dataStore.getDataItem(key: key)
    }
}
