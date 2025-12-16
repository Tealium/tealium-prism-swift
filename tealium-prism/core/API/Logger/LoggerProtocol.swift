//
//  LoggerProtocol.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A central utility class for processing log statements at various log levels.
 *
 * Log messages are not guaranteed to be processed immediately upon calling one of the logging methods,
 * however they will be processed in the order that they are received.
 *
 * **Important:** When using the logging methods, always use a limited set of non-dynamic categories.
 * Categories should be static strings that identify the component or feature being logged (e.g., "NetworkModule", "TraceModule").
 * Avoid using dynamic values like user IDs, timestamps, or other variable data as categories, as this can lead to
 * performance issues and potential memory problems in logging implementations.
 */
public protocol LoggerProtocol {
    /**
     * Asynchronously determines whether or not the given `level` should be logged by the currently configured `LogLevel.Minimum`.
     *
     * This method executes asynchronously to ensure thread-safe access to the logger's internal state.
     * The result is delivered via the completion handler.
     *
     * Note: The completion handler will be called with `true` when there is not a `LogLevel.Minimum` set yet.
     * Therefore, calling any of the logging methods (`trace`, `debug` etc) will queue the log message until
     * a `LogLevel.Minimum` has been set, deferring the decision on whether to log, or not, until then.
     *
     * - Parameters:
     *   - level: The `LogLevel` to compare against the currently configured `LogLevel.Minimum`.
     *   - completion: A closure called asynchronously with the result of whether the level should be logged.
     */
    func shouldLog(level: LogLevel, completion: @escaping (Bool) -> Void)

    /**
     * Logs a `trace` level message by evaluating the message passed in an autoclosure when and if log needs to take place.
     *
     * - Parameters:
     *   - category: The category or identifier associated with the log message.
     *   - messageProvider: The message to be recorded, only evaluated when and if log needs to take place.
     */
    func trace(category: String, _ messageProvider: @autoclosure @escaping () -> String)

    /**
     * Logs a `debug` level message by evaluating the message passed in an autoclosure when and if log needs to take place.
     *
     * - Parameters:
     *   - category: The category or identifier associated with the log message.
     *   - messageProvider: The message to be recorded, only evaluated when and if log needs to take place.
     */
    func debug(category: String, _ messageProvider: @autoclosure @escaping () -> String)

    /**
     * Logs an `info` level message by evaluating the message passed in an autoclosure when and if log needs to take place.
     *
     * - Parameters:
     *   - category: The category or identifier associated with the log message.
     *   - messageProvider: The message to be recorded, only evaluated when and if log needs to take place.
     */
    func info(category: String, _ messageProvider: @autoclosure @escaping () -> String)

    /**
     * Logs a `warn` level message by evaluating the message passed in an autoclosure when and if log needs to take place.
     *
     * - Parameters:
     *   - category: The category or identifier associated with the log message.
     *   - messageProvider: The message to be recorded, only evaluated when and if log needs to take place.
     */
    func warn(category: String, _ messageProvider: @autoclosure @escaping () -> String)

    /**
     * Logs an `error` level message by evaluating the message passed in an autoclosure when and if log needs to take place.
     *
     * - Parameters:
     *   - category: The category or identifier associated with the log message.
     *   - messageProvider: The message to be recorded, only evaluated when and if log needs to take place.
     */
    func error(category: String, _ messageProvider: @autoclosure @escaping () -> String)

    /**
     * Logs the provided level message by evaluating the message passed in an autoclosure when and if log needs to take place.
     *
     * - Parameters:
     *   - level: The level of the log.
     *   - category: The category or identifier associated with the log message.
     *   - messageProvider: The message to be recorded, only evaluated when and if log needs to take place.
     */
    func log(level: LogLevel, category: String, _ messageProvider: @autoclosure @escaping () -> String)
}

extension LoggerProtocol {
    func trace(category: String, _ messageProvider: @autoclosure @escaping () -> String) {
        log(level: .trace, category: category, messageProvider())
    }

    func debug(category: String, _ messageProvider: @autoclosure @escaping () -> String) {
        log(level: .debug, category: category, messageProvider())
    }

    func info(category: String, _ messageProvider: @autoclosure @escaping () -> String) {
        log(level: .info, category: category, messageProvider())
    }

    func warn(category: String, _ messageProvider: @autoclosure @escaping () -> String) {
        log(level: .warn, category: category, messageProvider())
    }

    func error(category: String, _ messageProvider: @autoclosure @escaping () -> String) {
        log(level: .error, category: category, messageProvider())
    }
}
