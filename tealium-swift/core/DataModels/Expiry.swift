//
//  Expiry.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/// The expiration type of some persisted value
public enum Expiry: Equatable {
    case session
    case untilRestart
    case forever
    case after(Date)

    /// Creates an `.after(Date)` expiry with a date that is value unit of time ahead of now.
    static func afterCustom(unit: TimeUnit, value: Int) -> Expiry {
        guard let date = dateWith(unit: unit, value: value) else {
            return .forever
        }
        return .after(date)
    }

    init(timestamp: Double) {
        switch timestamp {
        case -2:
            self = .session
        case -3:
            self = .untilRestart
        case -1:
            self = .forever
        default:
            self = .after(Date(timeIntervalSince1970: timestamp))
        }
    }

    func expiryTime() -> Double {
        switch self {
        case .session:
            return -2
        case .untilRestart:
            return -3
        case .forever:
            return -1
        case .after(let date):
            return date.timeIntervalSince1970
        }
    }

    private static func dateWith(unit: TimeUnit, value: Int) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        let currentDate = Date()
        components.setValue(value, for: unit.component)
        return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)
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
