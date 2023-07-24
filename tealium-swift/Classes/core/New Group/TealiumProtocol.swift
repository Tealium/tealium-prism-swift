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

public enum DispatchType: String {
    case event = "event"
    case view = "view"
}

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
    func asDictionary() -> [String: Any] {
        self
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
    
    public var name: String? {
        eventData[TealiumDataKey.event] as? String
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
    public let databaseHelper: DatabaseHelper?
    public weak var modulesManager: ModulesManager?
    
    @ToAnyObservable(TealiumReplaySubject<CoreSettings>())
    var onSettingsUpdate: TealiumObservable<CoreSettings>
    
    init(_ teal: TealiumProtocol, modulesManager: ModulesManager, config: TealiumConfig, coreSettings: CoreSettings, databaseHelper: DatabaseHelper?) {
        self.tealiumProtocol = teal
        self.modulesManager = modulesManager
        self.config = config
        self.coreSettings = coreSettings
        self.databaseHelper = databaseHelper
    }

    func updateSettings(_ dict: [String: Any]) {
        coreSettings.updateSettings(dict)
        _onSettingsUpdate.publish(coreSettings)
    }
}

public protocol Collector: TealiumModule {
    var data: TealiumDictionary { get }
}

public protocol Dispatcher: TealiumModule {
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
