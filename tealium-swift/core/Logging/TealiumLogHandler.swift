//
//  TealiumLogHandler.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import os.log

public protocol TealiumLogHandler: AnyObject {
    func log(category: String, message: String, level: TealiumLogLevel)
}

/// A basic implementation of `TealiumLogHandler` using system's OSLog API.
class TealiumOSLogger: TealiumLogHandler {
    var osLogs: [String: OSLog] = [:]

    func getOSLog(forCategory category: String) -> OSLog {
        if let osLog = osLogs[category] {
            return osLog
        }
        let newLog = OSLog(subsystem: "com.tealium.swift", category: category)
        osLogs[category] = newLog
        return newLog
    }

    func log(category: String, message: String, level: TealiumLogLevel) {
        os_log("%{public}@",
               log: getOSLog(forCategory: category),
               type: OSLogType.from(logLevel: level),
               message as NSString)
    }
}

extension OSLogType {
    static func from(logLevel: TealiumLogLevel) -> Self {
        switch logLevel {
        case .trace:
            /// `OSLog` doesn't have `trace`, so use `debug`
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        case .warn:
            /// `OSLog` doesn't have `warn`, so use `info`
            return .info
        case .error:
            return .error
        }
    }
}
