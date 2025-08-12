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

    /// The amount you need to multiply the current unit to approximately transform it to seconds.
    func toMillisecondsMultiplier() -> Int64 {
        switch self {
        case .milliseconds:
            1
        case .seconds:
            1000 * TimeUnit.milliseconds.toMillisecondsMultiplier()
        case .minutes:
            60 * TimeUnit.seconds.toMillisecondsMultiplier()
        case .hours:
            60 * TimeUnit.minutes.toMillisecondsMultiplier()
        case .days:
            24 * TimeUnit.hours.toMillisecondsMultiplier()
        }
    }

    func inSecondsMultiplier() -> Double {
        switch self {
        case .milliseconds:
            1 / 1000
        case .seconds:
            1
        case .minutes:
            60 * TimeUnit.seconds.inSecondsMultiplier()
        case .hours:
            60 * TimeUnit.minutes.inSecondsMultiplier()
        case .days:
            24 * TimeUnit.hours.inSecondsMultiplier()
        }
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

    func before(date: Date = Date()) -> Date? {
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
        unit.inSecondsMultiplier() * Double(interval)
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
        TimeFrame(unit: .milliseconds, interval: Int64(self))
    }
    var seconds: TimeFrame {
        TimeFrame(unit: .seconds, interval: Int64(self))
    }
    var minutes: TimeFrame {
        TimeFrame(unit: .minutes, interval: Int64(self))
    }
    var hours: TimeFrame {
        TimeFrame(unit: .hours, interval: Int64(self))
    }
    var days: TimeFrame {
        TimeFrame(unit: .days, interval: Int64(self))
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
