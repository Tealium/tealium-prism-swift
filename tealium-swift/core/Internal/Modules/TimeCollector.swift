//
//  TealiumTimeCollector.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

class TimeCollector: Collector, TealiumBasicModule {
    var version: String = TealiumConstants.libraryVersion
    static var id = "Time"
    static var canBeDisabled: Bool { true }
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {}

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        guard let timestampUnixMilliseconds = dispatchContext.initialData.getDataItem(key: TealiumDataKey.timestampUnixMilliseconds)?.get(as: Int64.self) else {
            return [:]
        }
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampUnixMilliseconds) / 1000)
        return [
            "timestamp": timestamp.iso8601String,
            "timestamp_local": timestamp.iso8601LocalString,
            "timestamp_offset": timestamp.timeZoneOffset,
            "timestamp_unix": timestamp.unixTimeSeconds,
            "timestamp_unix_milliseconds": timestamp.unixTimeMilliseconds,
            "tealium_timestamp_epoch": timestamp.timestampInSeconds
        ]
    }
}
