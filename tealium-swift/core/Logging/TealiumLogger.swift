//
//  TealiumLogger.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

public protocol TealiumLoggerProvider: AnyObject {
    var trace: TealiumLimitedLogger? { get }
    var debug: TealiumLimitedLogger? { get }
    var info: TealiumLimitedLogger? { get }
    var warn: TealiumLimitedLogger? { get }
    var error: TealiumLimitedLogger? { get }
}

/**
 * Use this class by extrapolating the appropriate logger for each desired log level and log with that specific logger.
 *
 * Normal usecase is to get one of the loggers and optional chain it to an in-line log like so:
 * ```
 * logger.debug?.log(category: "Some Category", message: "Some Message")
 * ```
 * Do not keep a reference of those loggers unless it's for logging multiple logs in a short sequence like:
 *
 * ```
 * if let trace = logger.trace {
 *    trace.log(category: "Some Category", message: "First Message")
 *    trace.log(category: "Some Category", message: "Second Message")
 * }
 * ```
 *
 * All the loggers provided by this class will only return a logger instance if that instance log level is higher than or equal to the minimum log level.
 * If the `minLogLevel` is nil, all logs are ignored.
 */
public class TealiumLogger: TealiumLoggerProvider {
    let logger: TealiumLogHandler?
    public internal(set) var minLogLevel: TealiumLogLevel.Minimum
    let autoDisposer = TealiumAutomaticDisposer()
    init(logger: TealiumLogHandler?, minLogLevel: TealiumLogLevel.Minimum, onCoreSettings: TealiumObservable<CoreSettings>) {
        self.logger = logger
        self.minLogLevel = minLogLevel
        onCoreSettings.subscribe { [weak self] settings in
            self?.minLogLevel = settings.minLogLevel
        }.addTo(autoDisposer)
    }

    private var _trace: TealiumLimitedLogger?
    public var trace: TealiumLimitedLogger? { getLogger(.trace) }

    private var _debug: TealiumLimitedLogger?
    public var debug: TealiumLimitedLogger? { getLogger(.debug) }

    private var _info: TealiumLimitedLogger?
    public var info: TealiumLimitedLogger? { getLogger(.info) }

    private var _warn: TealiumLimitedLogger?
    public var warn: TealiumLimitedLogger? { getLogger(.warn) }

    private var _error: TealiumLimitedLogger?
    public var error: TealiumLimitedLogger? { getLogger(.error) }

    func getLogger(_ level: TealiumLogLevel) -> TealiumLimitedLogger? {
        guard shouldLog(level) else {
            return nil
        }
        let keyPath = getKeyPath(forLogLevel: level)
        if let cachedLogger = self[keyPath: keyPath] {
            return cachedLogger
        } else {
            self[keyPath: keyPath] = TealiumLimitedLogger(logLevel: level, logger: logger) { [weak self] in self?.shouldLog(level) }
            return self[keyPath: keyPath]
        }
    }

    func getKeyPath(forLogLevel logLevel: TealiumLogLevel) -> ReferenceWritableKeyPath<TealiumLogger, TealiumLimitedLogger?> {
        switch logLevel {
        case .trace:
            return \._trace
        case .debug:
            return \._debug
        case .info:
            return \._info
        case .warn:
            return \._warn
        case .error:
            return \._error
        }
    }

    func shouldLog(_ logLevel: TealiumLogLevel) -> Bool {
        return logLevel >= minLogLevel
    }
}
