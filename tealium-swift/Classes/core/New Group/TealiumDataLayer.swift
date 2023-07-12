//
//  TealiumDataLayer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
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

    public func add(data: TealiumDictionaryOptionals, expiry: Expiry = .session) {
        getModule { dataLayer in // tealiumQueue
            dataLayer?.add(data: data, expiry: expiry)
        }
    }
    public func add(data: TealiumDictionary, expiry: Expiry = .session) {
        getModule { dataLayer in
            dataLayer?.add(data: data, expiry: expiry)
        }
    }
    public func add(key: String, value: TealiumDataValue, expiry: Expiry = .session) {
        getModule { dataLayer in
            dataLayer?.add(key: key, value: value, expiry: expiry)
        }
    }
    public func add(key: String, value: TealiumDataValue?, expiry: Expiry = .session) {
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
    public func getAllData(completion: @escaping ([String:Any]?) -> Void) {
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
    public var data: TealiumDictionary
    public static var id: String = "datalayer"
    
    public required init(context: TealiumContext, moduleSettings: [String : Any]) {
        self.data = [:]
    }
    
    let events = DataLayerEventPublishers()
    // TODO: Maybe put?
    func add(data: TealiumDictionaryOptionals, expiry: Expiry = .session) {
        add(data: TealiumDictionary(removingOptionals: data),
            expiry: expiry)
    }
    func add(data: TealiumDictionary, expiry: Expiry = .session) {
        events._onDataUpdated.publish(data)
        self.data += data
    }
    func add(key: String, value: TealiumDataValue, expiry: Expiry = .session) {
        events._onDataUpdated.publish([key: value])
        data[key] = value
    }
    func add(key: String, value: TealiumDataValue?, expiry: Expiry = .session) {
        if let value = value {
            add(key: key, value: value)
        }
    }
    func delete(key: String) {
        delete(keys: [key])
    }
    func deleteAll() {
        delete(keys: data.keys.map { $0 as String })
    }
    func delete(keys: [String]) {
        keys.forEach{ data.removeValue(forKey: $0) }
        events._onDataRemoved.publish(keys)
    }
    func getData(forKey key: String) -> Any? {
        data[key] // TODO: This will be a specific query
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
    
    public func onDataUpdated(_ event: @escaping ([String: Any]) -> Void) -> TealiumDisposableProtocol {
        extractor.onModule
            .flatMap { $0.events.onDataUpdated }
            .subscribe(event)
    }

    public func onDataRemoved(_ event: @escaping ([String]) -> Void) -> TealiumDisposableProtocol {
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

public class VisitorServiceEvents {
    let extractor: ModuleExtractor<VisitorServiceModule>
    init(moduleExtractor: ModuleExtractor<VisitorServiceModule>) {
        self.extractor = moduleExtractor
    }
    public func onVisitorProfileUpdate(_ event: @escaping ([String: Any]) -> Void) -> TealiumDisposableProtocol {
        extractor.onModule
            .flatMap { $0.events.onVisitorProfile }
            .subscribe(event)
    }
}
