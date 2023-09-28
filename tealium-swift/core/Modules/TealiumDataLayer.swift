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
    public var onModule: TealiumObservable<Module> {
        TealiumObservable.Callback { [weak self] callback in
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

    public func add(data: TealiumDictionaryInputOptionals, expiry: Expiry = .session) {
        getModule { dataLayer in // tealiumQueue
            dataLayer?.add(data: data, expiry: expiry)
        }
    }
    public func add(data: TealiumDictionaryInput, expiry: Expiry = .session) {
        getModule { dataLayer in
            dataLayer?.add(data: data, expiry: expiry)
        }
    }
    public func add(key: String, value: TealiumDataInput, expiry: Expiry = .session) {
        getModule { dataLayer in
            dataLayer?.add(key: key, value: value, expiry: expiry)
        }
    }
    public func add(key: String, value: TealiumDataInput?, expiry: Expiry = .session) {
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
    public func get(forKey key: String, completion: @escaping (Any?) -> Void) {
        getModule { dataLayer in
            completion(dataLayer?.getData(forKey: key))
        }
    }
    public func getAllData(completion: @escaping ([String: Any]?) -> Void) {
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

public class DataLayerModule: Collector {
    public var data: TealiumDictionaryInput {
        moduleStore.getAll().compactMapValues { $0.getDataInput() }
    }
    public static var id: String = "datalayer"
    let moduleStore: DataStore

    public required init?(context: TealiumContext, moduleSettings: [String: Any]) {
        do {
            moduleStore = try context.moduleStoreProvider.getModuleStore(name: Self.id)
        } catch {
            return nil
        }
    }

    let events = DataLayerEventPublishers()
    // TODO: Maybe put?
    func add(data: TealiumDictionaryInputOptionals, expiry: Expiry = .session) {
        add(data: TealiumDictionaryInput(removingOptionals: data),
            expiry: expiry)
    }
    func add(data: TealiumDictionaryInput, expiry: Expiry = .session) {
        try? moduleStore.edit()
            .putAll(dictionary: data, expiry: expiry)
            .commit()
    }
    func add(key: String, value: TealiumDataInput, expiry: Expiry = .session) {
        try? moduleStore.edit()
            .put(key: key, value: value, expiry: expiry)
            .commit()
    }
    func add(key: String, value: TealiumDataInput?, expiry: Expiry = .session) {
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
    func getData(forKey key: String) -> TealiumDataOutput? {
        moduleStore.get(key: key)
    }
}

public protocol DataLayerEventObservables {
    var onDataUpdated: TealiumObservable<[String: Any]> { get }
    var onDataRemoved: TealiumObservable<[String]> { get }
}

public class DataLayerEventPublishers: DataLayerEventObservables {
    fileprivate let _onDataUpdated = TealiumPublisher<[String: Any]>()
    fileprivate let _onDataRemoved = TealiumPublisher<[String]>()
    public private(set) lazy var onDataUpdated = _onDataUpdated.asObservable()
    public private(set) lazy var onDataRemoved = _onDataRemoved.asObservable()
}

public class DataLayerEvents {
    let extractor: ModuleExtractor<DataLayerModule>
    init(moduleExtractor: ModuleExtractor<DataLayerModule>) {
        self.extractor = moduleExtractor
    }

    public func onDataUpdated(_ event: @escaping ([String: Any]) -> Void) -> TealiumDisposable {
        extractor.onModule
            .flatMap { $0.events.onDataUpdated }
            .subscribe(event)
    }

    public func onDataRemoved(_ event: @escaping ([String]) -> Void) -> TealiumDisposable {
        extractor.onModule
            .flatMap { $0.events.onDataRemoved }
            .subscribe(event)
    }
}

public protocol VisitorServiceEventObservables {
    var onVisitorProfile: TealiumObservable<[String: Any]> { get }
}

public class VisitorServiceEventPublishers: VisitorServiceEventObservables {
    fileprivate let _onVisitorProfile = TealiumPublisher<[String: Any]>()
    public private(set) lazy var onVisitorProfile = _onVisitorProfile.asObservable()
}

class VisitorServiceModule: TealiumModule {
    static var id: String = "visitorservice"

    required init?(context: TealiumContext, moduleSettings: [String: Any]) {

    }

    let events = VisitorServiceEventPublishers()
}

public class VisitorServiceEvents {
    let extractor: ModuleExtractor<VisitorServiceModule>
    init(moduleExtractor: ModuleExtractor<VisitorServiceModule>) {
        self.extractor = moduleExtractor
    }
    public func onVisitorProfileUpdate(_ event: @escaping ([String: Any]) -> Void) -> TealiumDisposable {
        extractor.onModule
            .flatMap { $0.events.onVisitorProfile }
            .subscribe(event)
    }
}
