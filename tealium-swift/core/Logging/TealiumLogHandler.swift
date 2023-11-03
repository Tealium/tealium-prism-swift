//
//  TealiumLogHandler.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import os.log

public protocol TealiumLogHandler: AnyObject {
    // swiftlint:disable function_parameter_count
    func log(category: String, message: String, level: TealiumLogLevel, file: String, function: String, line: UInt)
    // swiftlint:enable function_parameter_count
}

extension TealiumLogHandler {
    func defaultFormat(message: String, level: TealiumLogLevel, file: String, function: String, line: UInt) -> String {
        var result = "\(level): \(message)"
        if case level = TealiumLogLevel.trace {
            result += "\nFile: \(file) - Function: \(function) - Line:\(line)"
        }
        return result
    }
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

    // swiftlint:disable function_parameter_count
    func log(category: String, message: String, level: TealiumLogLevel, file: String, function: String, line: UInt) {
        os_log("%{public}@",
               log: getOSLog(forCategory: category),
               type: OSLogType.from(logLevel: level),
               defaultFormat(message: message, level: level, file: file, function: function, line: line) as NSString)
    }
    // swiftlint:enable function_parameter_count
}

/// A basic implementation of `TealiumLogHandler` using system's print method.
class TealiumPrintLogger: TealiumLogHandler {
    // swiftlint:disable function_parameter_count
    func log(category: String, message: String, level: TealiumLogLevel, file: String, function: String, line: UInt) {
        print(format(category: category, message: message, level: level, file: file, function: function, line: line))
    }

    func format(category: String, message: String, level: TealiumLogLevel, file: String, function: String, line: UInt) -> String {
        "[\(category)] " + defaultFormat(message: message, level: level, file: file, function: function, line: line)
    }
    // swiftlint:enable function_parameter_count
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
