//
//  DataLayerWrapper.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

class DataLayerWrapper: DataLayer {
    let onDataUpdated: any Subscribable<DataObject>
    let onDataRemoved: any Subscribable<[String]>
    private let moduleProxy: ModuleProxy<DataLayerModule>
    init(moduleProxy: ModuleProxy<DataLayerModule>) {
        self.moduleProxy = moduleProxy
        onDataUpdated = moduleProxy.observeModule(\.dataStore.onDataUpdated)
        onDataRemoved = moduleProxy.observeModule(\.dataStore.onDataRemoved)
    }

    @discardableResult
    func transactionally(execute block: @escaping TransactionBlock) -> SingleResult<Void> {
        moduleProxy.executeModuleTask { module in
            let dataStore = module.dataStore
            let editor = dataStore.edit()
            try block({ edit in
                _ = editor.apply(edit: edit)
            }, { key in
                module.getDataItem(key: key)
            }, { try editor.commit() })
        }
    }

    @discardableResult
    func put(data: DataObject, expiry: Expiry) -> SingleResult<Void> {
        moduleProxy.executeModuleTask { module in
            try module.put(data: data, expiry: expiry)
        }
    }

    @discardableResult
    func put(key: String, value: DataInput, expiry: Expiry) -> SingleResult<Void> {
        moduleProxy.executeModuleTask { module in
            try module.put(key: key, value: value, expiry: expiry)
        }
    }

    @discardableResult
    func remove(key: String) -> SingleResult<Void> {
        moduleProxy.executeModuleTask { module in
            try module.remove(key: key)
        }
    }

    @discardableResult
    func remove(keys: [String]) -> SingleResult<Void> {
        moduleProxy.executeModuleTask { module in
            try module.remove(keys: keys)
        }
    }

    @discardableResult
    func clear() -> SingleResult<Void> {
        moduleProxy.executeModuleTask { module in
            try module.clear()
        }
    }

    func getDataItem(key: String) -> SingleResult<DataItem?> {
        moduleProxy.executeModuleTask { module in
            module.getDataItem(key: key)
        }
    }

    func getAll() -> SingleResult<DataObject> {
        moduleProxy.executeModuleTask { module in
            module.getAll()
        }
    }

    func get<T: DataInput>(key: String, as type: T.Type) -> SingleResult<T?> {
        moduleProxy.executeModuleTask { module in
            module.get(key: key, as: type)
        }
    }

    func getConvertible<T>(key: String, converter: any DataItemConverter<T>) -> SingleResult<T?> {
        moduleProxy.executeModuleTask { module in
            module.getConvertible(key: key, converter: converter)
        }
    }

    func getDataArray(key: String) -> SingleResult<[DataItem]?> {
        moduleProxy.executeModuleTask { module in
            module.getDataArray(key: key)
        }
    }

    func getDataDictionary(key: String) -> SingleResult<[String: DataItem]?> {
        moduleProxy.executeModuleTask { module in
            module.getDataDictionary(key: key)
        }
    }

    func getArray<T: DataInput>(key: String, of type: T.Type) -> SingleResult<[T?]?> {
        moduleProxy.executeModuleTask { module in
            module.getArray(key: key, of: type)
        }
    }

    func getDictionary<T: DataInput>(key: String, of type: T.Type) -> SingleResult<[String: T?]?> {
        moduleProxy.executeModuleTask { module in
            module.getDictionary(key: key, of: type)
        }
    }
}
