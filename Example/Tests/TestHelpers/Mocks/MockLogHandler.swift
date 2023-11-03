//
//  MockLogHandler.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockLogHandler: TealiumLogHandler {
    typealias LogEvent = (String, String, TealiumLogLevel)
    @ToAnyObservable<TealiumReplaySubject<LogEvent>>(TealiumReplaySubject<LogEvent>())
    var onLogged: TealiumObservable<LogEvent>
    // swiftlint:disable function_parameter_count
    func log(category: String, message: String, level: TealiumLogLevel, file: String, function: String, line: UInt) {
        _onLogged.publish((category, message, level))
    }
    // swiftlint:enable function_parameter_count
}
