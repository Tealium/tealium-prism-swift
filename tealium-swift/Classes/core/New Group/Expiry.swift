//
//  Expiry.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//

import Foundation

public enum Expiry {
    case session
    case untilRestart
    case forever
    case after(Date)
    case afterCustom((TimeUnit, Int))
    
    
    func expiryTime() -> Double {
        switch(self) {
        case .session:
            return -2
        case .untilRestart:
            return -3
        case .forever:
            return -1
        case .after(let date):
            return date.timeIntervalSince1970
        case .afterCustom(let (unit, value)):
            return dateWith(unit: unit, value: value)?.timeIntervalSince1970 ?? -2
        }
    }
    
    private func dateWith(unit: TimeUnit, value: Int) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        let currentDate = Date()
        components.setValue(value, for: unit.component)
        return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)
    }
    
    func timeRemaining() -> Double {
        switch(self) {
        case .session:
            return -2
        case .untilRestart:
            return -3
        case .forever:
            return -1
        case .after(let date):
            return date.timeIntervalSince1970 - Date().timeIntervalSince1970
        default:
            return -2
        }
    }
    
    static func fromValue(value: Double) -> Expiry {
        switch(value) {
        case -3:
            return .untilRestart
        case -2:
            return .session
        case -1:
            return .forever
        default:
            return .after(Date(timeIntervalSince1970: value))
        }
    }
    
    func isExpired() -> Bool {
        switch(self) {
        case .session, .forever, .untilRestart:
            return false
        default:
            return self.timeRemaining() < 0
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
