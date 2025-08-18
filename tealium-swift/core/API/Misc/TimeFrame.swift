//
//  TimeFrame.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TimeUnit {
    case milliseconds
    case seconds
    case minutes
    case hours
    case days

    /// The amount you need to multiply the current unit to transform it to milliseconds.
    func toMillisecondsMultiplier() -> Int64 {
        switch self {
        case .milliseconds: return 1
        case .seconds:      return 1000
        case .minutes:      return 60_000
        case .hours:        return 3_600_000
        case .days:         return 86_400_000
        }
    }

    /// The amount you need to multiply the current unit to transform it to seconds.
    func toSecondsMultiplier() -> Double {
        Double(toMillisecondsMultiplier()) / 1000
    }
}

public struct TimeFrame {
    public let unit: TimeUnit
    public let interval: Int64

    func afterNow() -> Date? {
        after(date: Date())
    }

    func after(date: Date) -> Date? {
        Self.dateDifference(date: date, interval: inSeconds(), for: .second)
    }

    func before(date: Date) -> Date? {
        Self.dateDifference(date: date, interval: -inSeconds(), for: .second)
    }

    func beforeNow() -> Date? {
        before(date: Date())
    }

    private static func dateDifference(date: Date, interval: Double, for component: Calendar.Component) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.setValue(Int(interval), for: component)
        return Calendar(identifier: .gregorian).date(byAdding: components, to: date)
    }

    /// Gets the amount of seconds approximately equivalent to this TimeFrame.
    func inSeconds() -> Double {
        unit.toSecondsMultiplier() * Double(interval)
    }

    /// Gets the amount of milliseconds equivalent to this TimeFrame. Will be coerced to be less than `Int64.max`
    func inMilliseconds() -> Int64 {
        let (partialValue, overflowHappened) = unit.toMillisecondsMultiplier().multipliedReportingOverflow(by: interval)
        if overflowHappened {
            return Int64.max
        }
        return partialValue
    }
}

public extension Int {
    var milliseconds: TimeFrame {
        Int64(self).milliseconds
    }
    var seconds: TimeFrame {
        Int64(self).seconds
    }
    var minutes: TimeFrame {
        Int64(self).minutes
    }
    var hours: TimeFrame {
        Int64(self).hours
    }
    var days: TimeFrame {
        Int64(self).days
    }
}

public extension Int64 {
    var milliseconds: TimeFrame {
        TimeFrame(unit: .milliseconds, interval: self)
    }
    var seconds: TimeFrame {
        TimeFrame(unit: .seconds, interval: self)
    }
    var minutes: TimeFrame {
        TimeFrame(unit: .minutes, interval: self)
    }
    var hours: TimeFrame {
        TimeFrame(unit: .hours, interval: self)
    }
    var days: TimeFrame {
        TimeFrame(unit: .days, interval: self)
    }
}

extension TimeFrame: Comparable, Equatable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        guard lhs.unit != rhs.unit else {
            return lhs.interval < rhs.interval
        }
        return lhs.inSeconds() < rhs.inSeconds()
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.unit != rhs.unit else {
            return lhs.interval == rhs.interval
        }
        return lhs.inSeconds() == rhs.inSeconds()
    }
}
