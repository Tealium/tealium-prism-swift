//
//  TealiumDataLayer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//

import Foundation

public class TealiumDataLayer: Collector {
    var data: TealiumDictionary
    
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
    func onDataRemoved() {
        
    }
    func onDataUpdated() {
        
    }
}
