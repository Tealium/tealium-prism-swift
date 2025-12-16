//
//  TealiumLogger.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

struct ErrorEvent {
    let category: String
    let descriptionProvider: () -> String
}

class TealiumLogger: LoggerProtocol {
    var minimumLevel: LogLevel.Minimum?
    let logHandler: LogHandler
    let onLogLevel: Observable<LogLevel.Minimum>
    let queue: TealiumQueue
    lazy private(set) var automaticDisposer = AutomaticDisposer()
    @Subject<ErrorEvent> var onError

    init(logHandler: LogHandler, onLogLevel: Observable<LogLevel.Minimum>, forceLevel: LogLevel.Minimum? = nil, queue: TealiumQueue = .worker) {
        self.logHandler = logHandler
        self.onLogLevel = onLogLevel
        self.minimumLevel = forceLevel
        self.queue = queue
        if forceLevel == nil {
            onLogLevel.subscribe { [weak self] level in
                self?.minimumLevel = level
            }.addTo(automaticDisposer)
        }
    }

    func shouldLog(level: LogLevel, completion: @escaping (Bool) -> Void) {
        queue.ensureOnQueue { [weak self] in
            guard let self else {
                completion(false)
                return
            }
            if let minimumLevel = self.minimumLevel {
                completion(level >= minimumLevel)
            } else {
                completion(true)
            }
        }
    }

    func log(level: LogLevel, category: String, _ messageProvider: @autoclosure @escaping () -> String) {
        queue.ensureOnQueue { [weak self] in
            if level == .error {
                self?._onError.publish(ErrorEvent(category: category, descriptionProvider: messageProvider))
            }
            self?.logOrQueue(level: level, category: category, messageProvider)
        }
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
        shouldLog(level: level) { [weak self] shouldLog in
            guard shouldLog else { return }
            self?.logHandler.log(category: category, message: message, level: level)
        }
    }
}
