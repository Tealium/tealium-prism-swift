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
 * but it will always be used by a logger to compare it with the `LogLevel.Minimum`
 * minimum log level and only send logs with higher severity than the configured minimum.
 */
public enum LogLevel: Int, Comparable, CaseIterable, CustomStringConvertible {
    case trace  = 0
    case debug  = 100
    case info   = 200
    case warn   = 300
    case error  = 400

    public static func >= (lhs: LogLevel, rhs: Minimum) -> Bool {
        lhs.rawValue >= rhs.rawValue
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
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
     * It includes the same log levels as the `LogLevel` plus an additional `silent` level to stop all logging.
     */
    public enum Minimum: Int, Comparable {
        case trace  = 0
        case debug  = 100
        case info   = 200
        case warn   = 300
        case error  = 400
        case silent = 999_999

        public init?(from string: String?) {
            guard let string else {
                return nil
            }
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

        public func toString() -> String {
            switch self {
            case .trace: "trace"
            case .debug: "debug"
            case .info: "info"
            case .warn: "warn"
            case .error: "error"
            case .silent: "silent"
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

extension LogLevel.Minimum: DataInputConvertible {
    public func toDataInput() -> any DataInput {
        toString()
    }
}

public enum TealiumLoggerType {
    case os // swiftlint:disable:this identifier_name
    case custom(LogHandler)

    func getHandler() -> LogHandler {
        switch self {
        case .os:
            return OSLogger()
        case .custom(let handler):
            return handler
        }
    }
}

public enum LogCategory {
    static let collect = "Collect"
    static let dispatchManager = "DispatchManager"
    static let httpClient = "HTTPClient"
    static let networkHelper = "NetworkHelper"
    static let queueManager = "QueueManager"
    static let resourceRefresher = "ResourceRefresher"
    static let settingsManager = "SettingsManager"
    static let sessionManager = "SessionManager"
    static let startup = "Startup"
    static let tealium = "Tealium"
    static let tracking = "Tracking"
    static let visitorIdProvider = "VisitorIdProvider"
    static let consent = "Consent"
}
