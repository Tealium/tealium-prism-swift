//
//  FailingMockDataStore.swift
//  tealium-prism
//
//  Created by Den Guzov on 13/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism

class FailingMockDataStore: DataStore {
    @Subject<DataObject> var onDataUpdated
    @Subject<[String]> var onDataRemoved

    func edit() -> DataStoreEditor {
        return FailingMockDataStoreEditor()
    }

    func getAll() -> DataObject {
        return DataObject()
    }

    func keys() -> [String] {
        return []
    }

    func count() -> Int {
        return 0
    }

    func getDataItem(key: String) -> DataItem? {
        return nil
    }

    func get<T>(key: String, converter: any DataItemConverter<T>) -> T? {
        return nil
    }
}

class FailingMockDataStoreEditor: DataStoreEditor {
    func put(key: String, value: any TealiumPrism.DataInput, expiry: TealiumPrism.Expiry) -> Self {
        return self
    }

    func remove(key: String) -> Self {
        return self
    }

    func apply(edit: DataStoreEdit) -> Self {
        return self
    }

    func putAll(dataObject: DataObject, expiry: Expiry) -> Self {
        return self
    }

    func remove(keys: [String]) -> Self {
        return self
    }

    func clear() -> Self {
        return self
    }

    func commit() throws {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock data store failure"])
    }
}
