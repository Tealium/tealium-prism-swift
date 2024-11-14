//
//  DataLayerWrapper.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

class DataLayerWrapper: DataLayer {
    let onDataUpdated: any Subscribable<DataObject>
    let onDataRemoved: any Subscribable<[String]>
    typealias Module = DataLayerModule
    private let moduleProxy: ModuleProxy<Module>
    init(moduleProxy: ModuleProxy<Module>) {
        self.moduleProxy = moduleProxy
        onDataUpdated = moduleProxy.observeModule { $0.moduleStore.onDataUpdated }
        onDataRemoved = moduleProxy.observeModule { $0.moduleStore.onDataRemoved }
    }

    private func getModule(completion: @escaping (Module?) -> Void) {
        moduleProxy.getModule(completion: completion)
    }
    func transactionally(execute block: @escaping TransactionBlock) {
        getModule { dataLayer in
            guard let dataLayer else { return }
            let dataStore = dataLayer.moduleStore
            let editor = dataStore.edit()
            block({ edit in
                _ = editor.apply(edit: edit)
            }, { key in
                dataLayer.getDataItem(key: key)
            }, { try editor.commit() })
        }
    }
    func put(data: DataObject, expiry: Expiry = .session) {
        getModule { dataLayer in
            dataLayer?.put(data: data, expiry: expiry)
        }
    }
    func put(key: String, value: DataInput, expiry: Expiry = .session) {
        getModule { dataLayer in
            dataLayer?.put(key: key, value: value, expiry: expiry)
        }
    }
    func remove(key: String) {
        getModule { dataLayer in
            dataLayer?.remove(key: key)
        }
    }
    func remove(keys: [String]) {
        getModule { dataLayer in
            dataLayer?.remove(keys: keys)
        }
    }
    func clear() {
        getModule { dataLayer in
            dataLayer?.removeAll()
        }
    }
    func getDataItem(key: String, completion: @escaping (DataItem?) -> Void) {
        getModule { dataLayer in
            completion(dataLayer?.getDataItem(key: key))
        }
    }
    func getAll(completion: @escaping (DataObject) -> Void) {
        getModule { dataLayer in
            guard let dataLayer else { return }
            completion(dataLayer.data)
        }
    }
}
