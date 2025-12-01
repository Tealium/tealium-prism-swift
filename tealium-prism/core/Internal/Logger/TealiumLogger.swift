//
//  TealiumLogger.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

struct ErrorEvent {
    let description: String
}

class TealiumLogger: LoggerProtocol {
    var minimumLevel: LogLevel.Minimum?
    let logHandler: LogHandler
    let onLogLevel: Observable<LogLevel.Minimum>
    lazy private(set) var automaticDisposer = AutomaticDisposer()
    @Subject<ErrorEvent> var onError

    init(logHandler: LogHandler, onLogLevel: Observable<LogLevel.Minimum>, forceLevel: LogLevel.Minimum? = nil) {
        self.logHandler = logHandler
        self.onLogLevel = onLogLevel
        self.minimumLevel = forceLevel
        if forceLevel == nil {
            onLogLevel.subscribe { [weak self] level in
                self?.minimumLevel = level
            }.addTo(automaticDisposer)
        }
    }

    func shouldLog(level: LogLevel) -> Bool {
        guard let minimumLevel else {
            return true
        }
        return level >= minimumLevel
    }

    func log(level: LogLevel, category: String, _ messageProvider: @autoclosure @escaping () -> String) {
        if level == .error {
            _onError.publish(ErrorEvent(description: "\(category): \(messageProvider())"))
        }
        logOrQueue(level: level, category: category, messageProvider)
    }

    private func logOrQueue(level: LogLevel, category: String, _ messageProvider: @escaping () -> String) {
        guard minimumLevel != nil else {
            enqueueLog(level: level, category: category, messageProvider)
            return
        }
        writeLog(level: level, category: category, messageProvider())
    }

    private func enqueueLog(level: LogLevel, category: String, _ messageProvider: @escaping () -> String) {
        onLogLevel.subscribeOnce { [weak self] _ in
            self?.writeLog(level: level, category: category, messageProvider())
        }.addTo(automaticDisposer)
    }

    private func writeLog(level: LogLevel, category: String, _ message: String) {
        guard shouldLog(level: level) else {
            return
        }
        logHandler.log(category: category, message: message, level: level)
    }
}
