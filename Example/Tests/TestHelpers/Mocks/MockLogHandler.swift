//
//  MockLogHandler.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 26/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockLogHandler: TealiumLogHandler {
    typealias LogEvent = (String, String, TealiumLogLevel)
    @ToAnyObservable<ReplaySubject<LogEvent>>(ReplaySubject<LogEvent>())
    var onLogged: Observable<LogEvent>
    func log(category: String, message: String, level: TealiumLogLevel) {
        _onLogged.publish((category, message, level))
    }
}

let verboseLogger = TealiumLogger(logger: TealiumOSLogger(),
                                  minLogLevel: .constant(.trace))
