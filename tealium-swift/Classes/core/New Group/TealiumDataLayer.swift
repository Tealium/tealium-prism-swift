//
//  TealiumDataLayer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//

import Foundation

public class TealiumDataLayer {
    let modulesManager: ModulesManager
    init(modulesManager: ModulesManager) {
        self.modulesManager = modulesManager
    }
    private func getDataLayerModule(completion: @escaping (DataLayerModule?) -> Void) {
        modulesManager.getModule(completion: completion)
    }

    func add(data: TealiumDictionaryOptionals, expiry: Expiry = .session) {
        getDataLayerModule { dataLayer in
            dataLayer?.add(data: data, expiry: expiry)
        }
    }
    func add(data: TealiumDictionary, expiry: Expiry = .session) {
        getDataLayerModule { dataLayer in
            dataLayer?.add(data: data, expiry: expiry)
        }
    }
    func add(key: String, value: TealiumDataValue, expiry: Expiry = .session) {
        getDataLayerModule { dataLayer in
            dataLayer?.add(key: key, value: value, expiry: expiry)
        }
    }
    func add(key: String, value: TealiumDataValue?, expiry: Expiry = .session) {
        getDataLayerModule { dataLayer in
            dataLayer?.add(key: key, value: value, expiry: expiry)
        }
    }
    func delete(key: String) {
        getDataLayerModule { dataLayer in
            dataLayer?.delete(key: key)
        }
    }
    func deleteAll() {
        getDataLayerModule { dataLayer in
            dataLayer?.deleteAll()
        }
    }
    func delete(keys: [String]) {
        getDataLayerModule { dataLayer in
            dataLayer?.delete(keys: keys)
        }
        onDataRemoved { data, removeHandler in
            print(data)
            // if i'm done
            removeHandler()
        }
    }
    
    /**
     * Need to experiment on this.
     * Atm we are passing a completion with the data and a remove handler
     *
     * This will probably be moved in the EventRouter, but even so, are we going to have the same issues?
     * The problem is that we want to always dispatch when we get from the public interface, otherwise people will register from different threads, which might lead to crashes.
     */
    func onDataRemoved(completion: @escaping (([String], () -> Void) -> Void)) {
        getDataLayerModule { dataLayer in
            var subscription: TealiumSubscription<[String]>?
            subscription = dataLayer?.onDataRemoved.subscribe { data in
                completion(data, { subscription?.dispose() })
            }
        }
    }
                
    func onDataUpdated(completion: @escaping (([String: Any]) -> Void) ) {
        getDataLayerModule { dataLayer in
            dataLayer?.onDataUpdated.subscribe(completion)
        }
    }
}

public class DataLayerModule: Collector {
    var data: TealiumDictionary
    /// Will receive events for data added or updated in the data layer
    @ToAnyObservable<TealiumPublisher>(TealiumPublisher<[String: Any]>())
    public var onDataUpdated: TealiumObservable<[String: Any]>

    /// Will receive events for data removed or expired from the data layer
    @ToAnyObservable<TealiumPublisher>(TealiumPublisher<[String]>())
    public var onDataRemoved: TealiumObservable<[String]>
    public static var id: String = "datalayer"
    
    public required init(context: TealiumContext, moduleSettings: [String : Any]) {
        self.data = [:]
    }
    
    // TODO: Maybe put?
    func add(data: TealiumDictionaryOptionals, expiry: Expiry = .session) {
        add(data: TealiumDictionary(removingOptionals: data),
            expiry: expiry)
    }
    func add(data: TealiumDictionary, expiry: Expiry = .session) {
        self.data += data
    }
    func add(key: String, value: TealiumDataValue, expiry: Expiry = .session) {
        data[key] = value
    }
    func add(key: String, value: TealiumDataValue?, expiry: Expiry = .session) {
        if let value = value {
            add(key: key, value: value)
        }
    }
    func delete(key: String) {
        data.removeValue(forKey: key)
    }
    func deleteAll() {
        data.removeAll()
    }
    func delete(keys: [String]) {
        keys.forEach(delete(key:))
    }
}
