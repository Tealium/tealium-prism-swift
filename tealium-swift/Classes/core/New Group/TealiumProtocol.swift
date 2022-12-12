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

public typealias TealiumDictionary = [String: TealiumDataValue?]

public struct TealiumDispatch {
    var eventData: TealiumDictionary
    
    public init(name: String, type: DispatchType = .event, data: TealiumDictionary?) {
        var eventData: TealiumDictionary = data ?? [:]
        eventData[TealiumDataKey.event] = name
        eventData[TealiumDataKey.eventType] = type.rawValue
        self.eventData = eventData
    }
    
    mutating func enrich(data: TealiumDictionary) {
        eventData += data
    }
}

public class TealiumTrace {
    func killVisitorSession() {}
    func join(id: String) {}
    func leave() {}
}


public class TealiumDeepLink {
    enum Referrer {
        case url(_ url: URL)
        case app(_ identifier: String)

        public static func fromUrl(_ url: URL?) -> Self? {
            guard let url = url else { return nil }
            return .url(url)
        }

        public static func fromAppId(_ identifier: String?) -> Self? {
            guard let id = identifier else { return nil }
            return .app(id)
        }
    }
    func handle(link: URL, referrer: Referrer? = nil) {}
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

public enum Expiry {
    case session
    case untilRestart
    case forever
    case after(Date)
    case afterCustom((TimeUnit, Int))

    public var date: Date? {
        switch self {
        case .after(let date):
            return date
        case .session, .forever:
            return distantDate()
        case .untilRestart:
            return Date()
        case .afterCustom(let (unit, value)):
            return dateWith(unit: unit, value: value)
        }
    }

    private func dateWith(unit: TimeUnit, value: Int) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        let currentDate = Date()
        components.setValue(value, for: unit.component)
        return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)
    }

    private func distantDate() -> Date? {
        dateWith(unit: .years, value: 100)
    }

    func isSession() -> Bool {
        switch self {
        case .session:
            return true
        default:
            return false
        }
    }

}

public enum TimeUnit {
    case minutes
    case hours
    case days
    case months
    case years

    public var component: Calendar.Component {
        switch self {
        case .minutes:
            return .minute
        case .hours:
            return .hour
        case .days:
            return .day
        case .months:
            return .month
        case .years:
            return .year
        }
    }
}

public class TealiumDataLayer: Collector {
    var data: TealiumDictionary
    
    public static var id: String = "datalayer"
    
    public var enabled: Bool = true
    
    public required init(context: TealiumContext, moduleSettings: [String : Any]) {
        self.data = [:]
    }
    
    public func updateSettings(settings: [String : Any]) {
        
    }
    
    func add(data: TealiumDictionary, expiry: Expiry = .session) {}
    func add(key: String, value: TealiumDataValue, expiry: Expiry = .session) {}
    func delete(key: String) {}
    func deleteAll() {}
    func delete(keys: [String]) {}
    func onDataRemoved() {}
    func onDataUpdated() {}
}

public class TealiumContext {
    public weak var tealiumProtocol: TealiumProtocol?
    public var config: TealiumConfig
    public var coreSettings: CoreSettings
    init(_ teal: TealiumProtocol, config: TealiumConfig, coreSettings: CoreSettings) {
        self.tealiumProtocol = teal
        self.config = config
        self.coreSettings = coreSettings
    }
}

protocol Collector: TealiumModule {
    var data: TealiumDictionary { get }
}

protocol Dispatcher: TealiumModule {
    func dispatch(_ data: TealiumDispatch)
}

public protocol TealiumModule {
    static var id: String { get }
    var enabled: Bool { get }
    init(context: TealiumContext, moduleSettings: [String: Any])
    
    func updateSettings(_ settings: [String: Any])
}

extension TealiumModule {
    public func updateSettings(_ settings: [String: Any]) {
        
    }
}

public protocol TealiumProtocol: AnyObject {
    init(_ config: TealiumConfig)
    func track(_ trackable: TealiumDispatch)
    func onReady(_ completion: @escaping () -> Void)
    
    var trace: TealiumTrace { get }
    var deepLink: TealiumDeepLink { get }
    var dataLayer: TealiumDataLayer? { get }
    var timedEvents: TealiumTimedEvents { get }
    var consent: TealiumConsent { get }
    var modules: [TealiumModule] { get }
}
