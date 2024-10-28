//
//  TealiumDataLayer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public class ModuleExtractor<Module: TealiumModule> {
    private weak var modulesManager: ModulesManager?
    init(modulesManager: ModulesManager) {
        self.modulesManager = modulesManager
    }
    public var onModule: Observable<Module> {
        Observable.Callback { [weak self] callback in
            self?.getModule(completion: callback)
        }.compactMap { $0 }
    }
    public func getModule(completion: @escaping (Module?) -> Void) {
        modulesManager?.getModule(completion: completion)
    }
}

public class TealiumDataLayer { // WRAPPER
    typealias Module = DataLayerModule
    public let events: DataLayerEvents
    private let moduleExtractor: ModuleExtractor<Module>
    init(modulesManager: ModulesManager) {
        let moduleExtractor = ModuleExtractor<Module>(modulesManager: modulesManager)
        self.moduleExtractor = moduleExtractor
        events = DataLayerEvents(moduleExtractor: moduleExtractor)
    }

    private func getModule(completion: @escaping (Module?) -> Void) {
        moduleExtractor.getModule(completion: completion)
    }

    public func add(data: DataObject, expiry: Expiry = .session) {
        getModule { dataLayer in
            dataLayer?.add(data: data, expiry: expiry)
        }
    }
    public func add(key: String, value: DataInput, expiry: Expiry = .session) {
        getModule { dataLayer in
            dataLayer?.add(key: key, value: value, expiry: expiry)
        }
    }
    public func add(key: String, value: DataInput?, expiry: Expiry = .session) {
        getModule { dataLayer in
            dataLayer?.add(key: key, value: value, expiry: expiry)
        }
    }
    public func delete(key: String) {
        getModule { dataLayer in
            dataLayer?.delete(key: key)
        }
    }
    public func deleteAll() {
        getModule { dataLayer in
            dataLayer?.deleteAll()
        }
    }
    public func delete(keys: [String]) {
        getModule { dataLayer in
            dataLayer?.delete(keys: keys)
        }
    }
    public func get(key: String, completion: @escaping (DataItem?) -> Void) {
        getModule { dataLayer in
            completion(dataLayer?.getDataItem(key: key))
        }
    }
    public func getAllData(completion: @escaping (DataObject?) -> Void) {
        getModule { dataLayer in
            completion(dataLayer?.data)
        }
    }
}

protocol DataLayerRemoveListener {
    func onDataRemove()
}
protocol DataLayerUpdateListener {
    func onDataUpdate()
}

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
            events = DataLayerEventPublishers(moduleStore)
        } catch {
            return nil
        }
    }

    let events: DataLayerEventPublishers
    // TODO: Maybe put?
    func add(data: DataObject, expiry: Expiry = .session) {
        try? moduleStore.edit()
            .putAll(dataObject: data, expiry: expiry)
            .commit()
    }
    func add(key: String, value: DataInput, expiry: Expiry = .session) {
        try? moduleStore.edit()
            .put(key: key, value: value, expiry: expiry)
            .commit()
    }
    func add(key: String, value: DataInput?, expiry: Expiry = .session) {
        if let value = value {
            add(key: key, value: value, expiry: expiry)
        }
    }
    func delete(key: String) {
        try? moduleStore.edit()
            .remove(key: key)
            .commit()
    }
    func deleteAll() {
        try? moduleStore.edit()
            .clear()
            .commit()
    }
    func delete(keys: [String]) {
        try? moduleStore.edit()
            .remove(keys: keys)
            .commit()
    }
    func getDataItem(key: String) -> DataItem? {
        moduleStore.getDataItem(key: key)
    }
}

public protocol DataLayerEventObservables {
    var onDataUpdated: Observable<DataObject> { get }
    var onDataRemoved: Observable<[String]> { get }
}

public class DataLayerEventPublishers: DataLayerEventObservables {
    init(_ store: DataStore) {
        onDataUpdated = store.onDataUpdated
        onDataRemoved = store.onDataRemoved
    }
    public let onDataUpdated: Observable<DataObject>
    public let onDataRemoved: Observable<[String]>
}

public class DataLayerEvents {
    let extractor: ModuleExtractor<DataLayerModule>
    init(moduleExtractor: ModuleExtractor<DataLayerModule>) {
        self.extractor = moduleExtractor
    }

    public func onDataUpdated(_ event: @escaping (DataObject) -> Void) -> Disposable {
        extractor.onModule
            .flatMap { $0.events.onDataUpdated }
            .subscribe(event)
    }

    public func onDataRemoved(_ event: @escaping ([String]) -> Void) -> Disposable {
        extractor.onModule
            .flatMap { $0.events.onDataRemoved }
            .subscribe(event)
    }
}

public protocol VisitorServiceEventObservables {
    var onVisitorProfile: Observable<DataObject> { get }
}

public class VisitorServiceEventPublishers: VisitorServiceEventObservables {
    fileprivate let _onVisitorProfile = BasePublisher<DataObject>()
    public private(set) lazy var onVisitorProfile = _onVisitorProfile.asObservable()
}

class VisitorServiceModule: TealiumModule {
    static let id: String = "visitorservice"

    required init?(context: TealiumContext, moduleSettings: DataObject) {

    }

    let events = VisitorServiceEventPublishers()
}

public class VisitorServiceEvents {
    let extractor: ModuleExtractor<VisitorServiceModule>
    init(moduleExtractor: ModuleExtractor<VisitorServiceModule>) {
        self.extractor = moduleExtractor
    }
    public func onVisitorProfileUpdate(_ event: @escaping (DataObject) -> Void) -> Disposable {
        extractor.onModule
            .flatMap { $0.events.onVisitorProfile }
            .subscribe(event)
    }
}
