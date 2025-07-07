//
//  Date+Tealium.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Date {
    init(unixMilliseconds: Int64) {
        self.init(timeIntervalSince1970: Double(unixMilliseconds) / 1000)
    }

    struct Formatter {
        static func getISOFormatter(timeZone: TimeZone?) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = timeZone
            return formatter
        }
        static let iso8601: DateFormatter = {
            let formatter = getISOFormatter(timeZone: TimeZone(secondsFromGMT: 0))
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            return formatter
        }()
        static let MMDDYYYY: DateFormatter = {
            let formatter = getISOFormatter(timeZone: TimeZone(secondsFromGMT: 0))
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter
        }()
        static let iso8601Local: DateFormatter = {
            let formatter = getISOFormatter(timeZone: TimeZone.autoupdatingCurrent)
            // note that local time should NOT have a 'Z' after it, as the 'Z' indicates UTC (zero meridian)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return formatter
        }()
        static let iso8601LocalWithOffset: DateFormatter = {
            let formatter = getISOFormatter(timeZone: TimeZone.autoupdatingCurrent)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            return formatter
        }()
    }

    var iso8601String: String {
        return Formatter.iso8601.string(from: self)
    }

    var iso8601LocalString: String {
        return Formatter.iso8601Local.string(from: self)
    }
    var iso8601LocalWithOffsetString: String {
        return Formatter.iso8601LocalWithOffset.string(from: self)
    }

    var mmDDYYYYString: String {
        return Formatter.MMDDYYYY.string(from: self)
    }

    var unixTimeMilliseconds: Int64 {
        // must be forced to Int64 to avoid overflow on watchOS (32 bit)
        Int64(self.timeIntervalSince1970 * 1000)
    }

    var unixTimeSeconds: Int64 {
        // must be forced to Int64 to avoid overflow on watchOS (32 bit)
        Int64(self.timeIntervalSince1970)
    }

    func millisecondsFrom(earlierDate: Date) -> Int64 {
        return Int64(self.timeIntervalSince(earlierDate) * 1000)
    }

    func addSeconds(_ seconds: Double?) -> Date? {
        guard let seconds = seconds else {
            return nil
        }
        guard let timeInterval = TimeInterval(exactly: seconds) else {
            return nil
        }
        return addingTimeInterval(timeInterval)
    }

    func addMinutes(_ mins: Double?) -> Date? {
        guard let mins = mins else {
            return nil
        }
        let seconds = mins * 60
        guard let timeInterval = TimeInterval(exactly: seconds) else {
            return nil
        }
        return addingTimeInterval(timeInterval)
    }

    var timeZoneOffset: Float {
        let timezone = TimeZone.current
        let offsetSeconds = timezone.secondsFromGMT()
        let offsetHours = Float(offsetSeconds) / 3600
        return offsetHours
    }
}
