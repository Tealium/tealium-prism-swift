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

protocol TealiumDataValue {}
extension Double: TealiumDataValue {}
extension Int: TealiumDataValue {}
extension String: TealiumDataValue {}

enum DispatchType: String {
    case event = "event"
    case view = "view"
}

struct TealiumDispatch {
    var eventData: [String : TealiumDataValue]
    
    init(name: String, type: DispatchType = .event, data: [String: TealiumDataValue]?) {
        var eventData: [String: TealiumDataValue] = data ?? [:]
        eventData[TealiumDataKey.event] = name
        eventData[TealiumDataKey.eventType] = type.rawValue
        self.eventData = eventData
    }
}

class TealiumConfig {
    
}

class TealiumTrace {
    
}

class TealiumDeepLink {
    
}

class TealiumTimedEvents {
    
}

class TealiumConsent {
    
}

class TealiumDataLayer {
    
}

class TealiumContext {
    weak var tealiumProtocol: TealiumProtocol?
}

protocol Collector {
    var data: [String: Any] { get }
}

protocol Dispatcher {
    func dispatch(_ data: TealiumDispatch)
}

protocol TealiumModule {
    init(_ context: TealiumContext)
}

protocol TealiumProtocol: AnyObject {
    init(_ config: TealiumConfig)
    func track(_ trackable: TealiumDispatch)
    func onReady(_ completion: @escaping () -> Void)
    
    var trace: TealiumTrace { get }
    var deepLink: TealiumDeepLink { get }
    var dataLayer: TealiumDataLayer { get }
    var timedEvents: TealiumTimedEvents { get }
    var consent: TealiumConsent { get }
    var modules: [TealiumModule] { get }
}
