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
    case months
    case years

    /// The amount you need to multiply the current unit to approximately transform it to seconds.
    func toSecondsMultiplier() -> Double {
        switch self {
        case .milliseconds:
            1 / 1000
        case .seconds:
            1
        case .minutes:
            60
        case .hours:
            60 * TimeUnit.minutes.toSecondsMultiplier()
        case .days:
            24 * TimeUnit.hours.toSecondsMultiplier()
        case .months:
            365 / 12 * TimeUnit.days.toSecondsMultiplier()
        case .years:
            365 * TimeUnit.days.toSecondsMultiplier()
        }
    }
}

public struct TimeFrame {
    let unit: TimeUnit
    let interval: Double

    func dateAfter(date: Date = Date()) -> Date? {
        Self.dateDifference(date: date, interval: seconds(), for: .second)
    }

    func dateBefore(date: Date = Date()) -> Date? {
        Self.dateDifference(date: date, interval: -seconds(), for: .second)
    }

    private static func dateDifference(date: Date, interval: Double, for component: Calendar.Component) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        components.setValue(Int(interval), for: component)
        return Calendar(identifier: .gregorian).date(byAdding: components, to: date)
    }

    /// Gets the amount of seconds approximately equivalent to this TimeFrame.
    func seconds() -> Double {
        unit.toSecondsMultiplier() * interval
    }
}

public extension Int {
    var milliseconds: TimeFrame {
        TimeFrame(unit: .milliseconds, interval: Double(self))
    }
    var seconds: TimeFrame {
        TimeFrame(unit: .seconds, interval: Double(self))
    }
    var minutes: TimeFrame {
        TimeFrame(unit: .minutes, interval: Double(self))
    }
    var hours: TimeFrame {
        TimeFrame(unit: .hours, interval: Double(self))
    }
    var days: TimeFrame {
        TimeFrame(unit: .days, interval: Double(self))
    }
}

extension TimeFrame: DataInputConvertible {
    public func toDataInput() -> any DataInput {
        seconds()
    }
}

extension TimeFrame {
    struct Converter: DataItemConverter {
        typealias Convertible = TimeFrame
        func convert(dataItem: DataItem) -> Convertible? {
            guard let seconds = dataItem.get(as: Double.self) else { return nil }
            return TimeFrame(unit: .seconds, interval: seconds)
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}

extension TimeFrame: Comparable, Equatable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        guard lhs.unit != rhs.unit else {
            return lhs.interval < rhs.interval
        }
        return lhs.seconds() < rhs.seconds()
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.unit != rhs.unit else {
            return lhs.interval == rhs.interval
        }
        return lhs.seconds() == rhs.seconds()
    }
}
