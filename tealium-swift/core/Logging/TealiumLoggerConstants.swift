//
//  TealiumLoggerConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * The various levels of severity that can be attached to a single log.
 *
 * The higher the rawValue of the log level, the more important it is to be logged.
 * The log level can be used by a `TealiumLogHandler` to log differently the data it receives
 * (e.g.: Red color for `error`, or more data for `trace` vs `debug`)
 * but it will always be used by a logger to compare it with the `TealiumLogLevel.Minimum`
 * minimum log level and only send logs with higher severity than the configured minimum.
 */
public enum TealiumLogLevel: Int, Comparable, CaseIterable, CustomStringConvertible {
    case trace  = 0
    case debug  = 100
    case info   = 200
    case warn   = 300
    case error  = 400

    public static func >= (lhs: TealiumLogLevel, rhs: Minimum) -> Bool {
        lhs.rawValue >= rhs.rawValue
    }

    public static func < (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .trace:
            return "Trace"
        case .debug:
            return "Debug"
        case .info:
            return "Info"
        case .warn:
            return "Warning"
        case .error:
            return "Error"
        }
    }
    /**
     * The minimum log level that will be used by a logger to limit the amount of logs produced.
     *
     * It includes the same log levels as the TealiumLogLevel plus an additional `silent` level to stop all logging.
     */
    public enum Minimum: Int, Comparable {
        case trace  = 0
        case debug  = 100
        case info   = 200
        case warn   = 300
        case error  = 400
        case silent = 999_999

        // TODO: Switch back to an .error default
        static let `default` = Self.debug

        public init?(from string: String) {
            switch string {
            case "trace":
                self = .trace
            case "debug":
                self = .debug
            case "info":
                self = .info
            case "warn":
                self = .warn
            case "error":
                self = .error
            case "silent", "none":
                self = .silent
            default:
                return nil
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// swiftlint:disable identifier_name
public enum TealiumLoggerType {
    case print
    case os
    case custom(TealiumLogHandler)

    func getHandler() -> TealiumLogHandler {
        switch self {
        case .print:
            return TealiumPrintLogger()
        case .os:
            return TealiumOSLogger()
        case .custom(let handler):
            return handler
        }
    }
}
// swiftlint:enable identifier_name

enum TealiumLibraryCategories {
    static let startup = "Startup"
    static let tracking = "Tracking"
    static let collecting = "Collecting"
    static let dispatching = "Dispatching"
    static let settings = "Settings"
    static let networking = "Networking"
}
