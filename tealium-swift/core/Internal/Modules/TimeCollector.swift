//
//  TealiumTimeCollector.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumDataKey {
    /// The timestamp in `ISO 8601` UTC string.
    static let timestampUtc = "tealium_timestamp_utc"
    /// The timestamp in `ISO 8601` Local string.
    static let timestampLocal = "tealium_timestamp_local"
    /// The timestamp in `ISO 8601` Local string with the offset expressed in `+|-HH:mm` or `Z` for GMT without daylight savings.
    static let timestampLocalWithOffset = "tealium_timestamp_local_with_offset"
    /**
     * The timezone offset in decimal hours.
     *
     * Examples:
     * ```
     * +08:00 == 8
     * +05:45 == 5.75
     * -04:00 == -4
     * -01:30 == -1.5
     * ```
     */
    static let timezoneOffset = "tealium_timestamp_offset"
    /// The timestamp in unix seconds.
    static let timestampUnix = "tealium_timestamp_epoch"
    /// The timestamp in unix milliseconds.
    static let timestampUnixMilliseconds = "tealium_timestamp_epoch_milliseconds"
    /// The time zone the user is located in.
    static let timestampTimezone = "tealium_timestamp_timezone"
}

class TimeCollector: Collector, BasicModule {
    let version: String = TealiumConstants.libraryVersion
    static var id = "Time"
    static var canBeDisabled: Bool { true }
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {}

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        guard let timestampUnixMilliseconds = dispatchContext.initialData
            .get(key: TealiumDataKey.timestampUnixMilliseconds, as: Int64.self) else {
            return [:]
        }
        let date = Date(unixMilliseconds: timestampUnixMilliseconds)
        return [
            TealiumDataKey.timestampUtc: date.iso8601String,
            TealiumDataKey.timestampLocal: date.iso8601LocalString,
            TealiumDataKey.timestampLocalWithOffset: date.iso8601LocalWithOffsetString,
            TealiumDataKey.timezoneOffset: date.timeZoneOffset,
            TealiumDataKey.timestampUnix: date.unixTimeSeconds,
            TealiumDataKey.timestampUnixMilliseconds: timestampUnixMilliseconds,
            TealiumDataKey.timestampTimezone: TimeZone.current.identifier
        ]
    }
}
