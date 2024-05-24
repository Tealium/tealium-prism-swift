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
        guard let date = TimeFrame(unit: unit, interval: value).dateAfter() else {
            return .forever
        }
        return .after(date)
    }

    init(timestamp milliseconds: Int64) {
        switch milliseconds {
        case -2:
            self = .session
        case -3:
            self = .untilRestart
        case -1:
            self = .forever
        default:
            self = .after(Date(timeIntervalSince1970: Double(milliseconds) / 1000))
        }
    }

    func expiryTime() -> Int64 {
        switch self {
        case .session:
            return -2
        case .untilRestart:
            return -3
        case .forever:
            return -1
        case .after(let date):
            return date.unixTimeMillisecondsInt
        }
    }
}

public enum TimeUnit {
    case seconds
    case minutes
    case hours
    case days
    case months
    case years

    public var component: Calendar.Component {
        switch self {
        case .seconds:
            return .second
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

public struct TimeFrame {
    let unit: TimeUnit
    let interval: Int

    func dateAfter(date: Date = Date()) -> Date? {
        Self.dateDifference(date: date, interval: interval, for: unit.component)
    }

    func dateBefore(date: Date = Date()) -> Date? {
        Self.dateDifference(date: date, interval: -interval, for: unit.component)
    }

    private static func dateDifference(date: Date, interval: Int, for component: Calendar.Component) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.setValue(interval, for: component)
        return Calendar(identifier: .gregorian).date(byAdding: components, to: date)
    }
}

extension TimeFrame: Comparable, Equatable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        guard lhs.unit != rhs.unit else {
            return lhs.interval < rhs.interval
        }
        let date = Date()
        guard let lhsAfter = lhs.dateAfter(date: date), let rhsAfter = rhs.dateAfter(date: date) else {
            return false
        }
        return lhsAfter < rhsAfter
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.unit != rhs.unit else {
            return lhs.interval == rhs.interval
        }
        let date = Date()
        guard let lhsAfter = lhs.dateAfter(date: date), let rhsAfter = rhs.dateAfter(date: date) else {
            return false
        }
        return lhsAfter == rhsAfter
    }
}
