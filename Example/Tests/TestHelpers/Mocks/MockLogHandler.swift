//
//  MockLogHandler.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 26/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

class MockLogHandler: LogHandler {
    struct LogEvent {
        let category: String
        let message: String
        let level: LogLevel
    }
    @Subject<LogEvent> var onLogged

    func log(category: String, message: String, level: LogLevel) {
        _onLogged.onNext(LogEvent(category: category, message: message, level: level))
    }

    /// Runs `block`, and returns the events logged meanwhile.
    func eventsLoggedWhileExecuting(_ block: () throws -> Void) rethrows -> [LogEvent] {
        var logged = [LogEvent]()
        let subscription = onLogged.subscribe { logged.append($0) }
        defer { subscription.dispose() }
        try block()
        return logged
    }

    /// Runs `block`, and returns the messages logged meanwhile at `level`, in `category` when given.
    func messagesLogged(at level: LogLevel, in category: String? = nil, whileExecuting block: () throws -> Void) rethrows -> [String] {
        try eventsLoggedWhileExecuting(block).messages(at: level, in: category)
    }
}

extension Array where Element == MockLogHandler.LogEvent {
    /// The messages of the events at `level`, in `category` when given.
    func messages(at level: LogLevel, in category: String? = nil) -> [String] {
        filter { $0.level == level && (category == nil || $0.category == category) }
            .map { $0.message }
    }
}

struct MockLogger: LoggerProtocol {
    let handler = MockLogHandler()
    func shouldLog(level: LogLevel, completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    func log(level: LogLevel, category: String, _ messageProvider: @autoclosure @escaping () -> String) {
        handler.log(category: category, message: messageProvider(), level: level)
    }
}
