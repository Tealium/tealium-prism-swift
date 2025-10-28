//
//  TimeFrame.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/// Units of time measurement.
public enum TimeUnit {
    /// Time measured in milliseconds.
    case milliseconds
    /// Time measured in seconds.
    case seconds
    /// Time measured in minutes.
    case minutes
    /// Time measured in hours.
    case hours
    /// Time measured in days.
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

/// Represents a duration of time with a specific unit and interval.
public struct TimeFrame {
    /// The unit of time measurement.
    public let unit: TimeUnit
    /// The number of time units.
    public let interval: Int64

    /// Returns a `Date` representing the time after the current moment by the duration of this `TimeFrame`.
    func afterNow() -> Date {
        after(date: Date())
    }

    /// Returns a `Date` representing the time after the specified date by the duration of this `TimeFrame`.
    func after(date: Date) -> Date {
        Self.dateDifference(date: date, milliseconds: inMilliseconds())
    }

    /// Returns a `Date` representing the time before the specified date by the duration of this `TimeFrame`.
    func before(date: Date) -> Date {
        Self.dateDifference(date: date, milliseconds: -inMilliseconds())
    }

    /// Returns a `Date` representing the time before the current moment by the duration of this `TimeFrame`.
    func beforeNow() -> Date {
        before(date: Date())
    }

    private static func dateDifference(date: Date, milliseconds: Int64) -> Date {
        var (timestamp, overflow) = date.unixTimeMilliseconds.addingReportingOverflow(milliseconds)
        if overflow {
            timestamp = Int64.max * milliseconds.signum()
        }
        return Date(unixMilliseconds: timestamp)
    }

    /// Gets the amount of seconds approximately equivalent to this TimeFrame.
    public func inSeconds() -> Double {
        unit.toSecondsMultiplier() * Double(interval)
    }

    /// Gets the amount of milliseconds equivalent to this TimeFrame. Will be coerced to be less than `Int64.max`
    public func inMilliseconds() -> Int64 {
        let (partialValue, overflowHappened) = unit.toMillisecondsMultiplier().multipliedReportingOverflow(by: interval)
        if overflowHappened {
            return Int64.max
        }
        return partialValue
    }
}

public extension Int {
    /// Creates a TimeFrame representing this many milliseconds.
    var milliseconds: TimeFrame {
        Int64(self).milliseconds
    }
    /// Creates a TimeFrame representing this many seconds.
    var seconds: TimeFrame {
        Int64(self).seconds
    }
    /// Creates a TimeFrame representing this many minutes.
    var minutes: TimeFrame {
        Int64(self).minutes
    }
    /// Creates a TimeFrame representing this many hours.
    var hours: TimeFrame {
        Int64(self).hours
    }
    /// Creates a TimeFrame representing this many days.
    var days: TimeFrame {
        Int64(self).days
    }
}

public extension Int64 {
    /// Creates a TimeFrame representing this many milliseconds.
    var milliseconds: TimeFrame {
        TimeFrame(unit: .milliseconds, interval: self)
    }
    /// Creates a TimeFrame representing this many seconds.
    var seconds: TimeFrame {
        TimeFrame(unit: .seconds, interval: self)
    }
    /// Creates a TimeFrame representing this many minutes.
    var minutes: TimeFrame {
        TimeFrame(unit: .minutes, interval: self)
    }
    /// Creates a TimeFrame representing this many hours.
    var hours: TimeFrame {
        TimeFrame(unit: .hours, interval: self)
    }
    /// Creates a TimeFrame representing this many days.
    var days: TimeFrame {
        TimeFrame(unit: .days, interval: self)
    }
}

/// TimeFrame comparison and equality implementations.
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
