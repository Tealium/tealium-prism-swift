//
//  MockLogHandler.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockLogHandler: LogHandler {
    struct LogEvent {
        let category: String
        let message: String
        let level: LogLevel
    }
    @ToAnyObservable<ReplaySubject<LogEvent>>(ReplaySubject<LogEvent>())
    var onLogged: Observable<LogEvent>
    func log(category: String, message: String, level: LogLevel) {
        _onLogged.publish(LogEvent(category: category, message: message, level: level))
    }
}

struct MockLogger: LoggerProtocol {
    func shouldLog(level: LogLevel) -> Bool {
        return true
    }

    func log(level: LogLevel, category: String, _ messageProvider: @autoclosure @escaping () -> String) {

    }
}

let verboseLogger = TealiumLogger(logHandler: OSLogger(),
                                  onLogLevel: .Empty(),
                                  forceLevel: .trace)
