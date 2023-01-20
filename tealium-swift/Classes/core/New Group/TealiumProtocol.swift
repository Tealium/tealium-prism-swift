//
//  TealiumProtocol.swift
//  tealium-swift
//
//  Created by Tyler Rister on 12/5/22.
//

import Foundation

//protocol TealiumTrackable {
//    var eventData: [String: Any] { get }
//}

public protocol TealiumDataValue {}
extension Double: TealiumDataValue {}
extension Int: TealiumDataValue {}
extension String: TealiumDataValue {}
extension Array<String>: TealiumDataValue {}


public enum DispatchType: String {
    case event = "event"
    case view = "view"
}

public typealias TealiumDictionary = [String: TealiumDataValue]
public typealias TealiumDictionaryOptionals = [String: TealiumDataValue?]

public extension TealiumDictionary {
    
    init(removingOptionals elements: TealiumDictionaryOptionals ) {
        self.init(uniqueKeysWithValues: elements.compactMap({ key, value in
            guard let value = value else { return nil }
            return (key, value)
        }))
    }
    
    subscript(removingOptionals key: String) -> TealiumDataValue? {
        get {
            self[key]
        }
        set {
            if let value = newValue {
                self[key] = value
            }
        }
    }
}

public struct TealiumDispatch {
    var eventData: TealiumDictionary
    
    public init(name: String, type: DispatchType = .event, data: TealiumDictionary? = nil) {
        var eventData: TealiumDictionary = data ?? [:]
        eventData[TealiumDataKey.event] = name
        eventData[TealiumDataKey.eventType] = type.rawValue
        self.eventData = eventData
    }
    
    mutating func enrich(data: TealiumDictionary) {
        eventData += data
    }
}

public class TealiumTimedEvents {
    func start(event name: String, with data: [String: Any]? = [String: Any]()) {}
    func stop(event name: String) {}
    func cancel(event name: String) {}
    func cancelAll() {}
}

public class TealiumConsent {
    //func grant(withPurpose: )
}

public class TealiumContext {
    public weak var tealiumProtocol: TealiumProtocol?
    public let config: TealiumConfig
    public var coreSettings: CoreSettings
    public let modulesManager: ModulesManager
    init(_ teal: TealiumProtocol, modulesManager: ModulesManager, config: TealiumConfig, coreSettings: CoreSettings) {
        self.tealiumProtocol = teal
        self.modulesManager = modulesManager
        self.config = config
        self.coreSettings = coreSettings
    }
}

protocol Collector: TealiumModule {
    var data: TealiumDictionary { get }
}

protocol Dispatcher: TealiumModule {
    func dispatch(_ data: [TealiumDispatch])
}

public protocol TealiumModule {
    static var id: String { get }
    init?(context: TealiumContext, moduleSettings: [String: Any])
    
    func updateSettings(_ settings: [String: Any]) -> Self?
}

extension TealiumModule {
    public func updateSettings(_ settings: [String: Any]) -> Self? {
        return self
    }
}

public protocol TealiumProtocol: AnyObject {
    init(_ config: TealiumConfig)
    func track(_ trackable: TealiumDispatch)
    func onReady(_ completion: @escaping () -> Void)
    
    var trace: TealiumTrace { get }
    var deepLink: TealiumDeepLink { get }
    var dataLayer: TealiumDataLayer { get }
    var timedEvents: TealiumTimedEvents { get }
    var consent: TealiumConsent { get }
    var modules: [TealiumModule] { get }
    func getModule<T: TealiumModule>(completion: @escaping (T?) -> Void)
}
