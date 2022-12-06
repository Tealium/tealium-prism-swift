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

public enum DispatchType: String {
    case event = "event"
    case view = "view"
}

public struct TealiumDispatch {
    var eventData: [String : TealiumDataValue]
    
    public init(name: String, type: DispatchType = .event, data: [String: TealiumDataValue]?) {
        var eventData: [String: TealiumDataValue] = data ?? [:]
        eventData[TealiumDataKey.event] = name
        eventData[TealiumDataKey.eventType] = type.rawValue
        self.eventData = eventData
    }
    
    mutating func enrich(data: [String: TealiumDataValue]) {
        eventData += data
    }
}

public class TealiumTrace {
    
}

public class TealiumDeepLink {
    
}

public class TealiumTimedEvents {
    
}

public class TealiumConsent {
    
}

public class TealiumDataLayer {
    
}

public class TealiumContext {
    public weak var tealiumProtocol: TealiumProtocol?
    public var config: CoreConfig
    init(_ teal: TealiumProtocol, config: CoreConfig) {
        self.tealiumProtocol = teal
        self.config = config
    }
}

protocol Collector: TealiumModule {
    var data: [String: TealiumDataValue] { get }
}

protocol Dispatcher: TealiumModule {
    func dispatch(_ data: TealiumDispatch)
}

public protocol TealiumModule {
    static var id: String { get }
    init(_ context: TealiumContext, config: [String: Any])
}

public protocol TealiumProtocol: AnyObject {
    init(_ config: CoreConfig)
    func track(_ trackable: TealiumDispatch)
    func onReady(_ completion: @escaping () -> Void)
    
    var trace: TealiumTrace { get }
    var deepLink: TealiumDeepLink { get }
    var dataLayer: TealiumDataLayer { get }
    var timedEvents: TealiumTimedEvents { get }
    var consent: TealiumConsent { get }
    var modules: [TealiumModule] { get }
}
