//
//  TealiumLimitedLogger.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A wrapper class that can be used to limit the amount of logs it needs to send.
 *
 * It will always send the log with the level in which this instance was created and only when it's instructed that it should log.
 */
public class TealiumLimitedLogger {
    private let logLevel: TealiumLogLevel
    private weak var logger: TealiumLogHandler?
    private let shouldLog: () -> Bool?

    init(logLevel: TealiumLogLevel, logger: TealiumLogHandler?, shouldLog: @escaping () -> Bool?) {
        self.logLevel = logLevel
        self.logger = logger
        self.shouldLog = shouldLog
    }

    public func log(category: String,
                    message: String,
                    file: String = #file,
                    function: String = #function,
                    line: UInt = #line) {
        guard shouldLog() == true else { return }
        logger?.log(category: category,
                    message: message,
                    level: logLevel,
                    file: file,
                    function: function,
                    line: line)
    }
}
