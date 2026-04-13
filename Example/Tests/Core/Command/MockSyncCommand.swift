//
//  MockSyncCommand.swift
//  TealiumPrismCoreTests
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation
@testable import TealiumPrism

/// Mock implementation of `SyncCommand` for testing command execution.
/// Tracks execution calls and can be configured to succeed or throw an error.
class MockSyncCommand: SyncCommand {

    let errorToThrow: CommandError?

    var executeCalled = false
    var lastPayload: DataObject?
    var executeCallCount = 0

    init(name: String, errorToThrow: CommandError? = nil) {
        self.errorToThrow = errorToThrow
        super.init(name: name)
    }

    override func execute(payload: DataObject) throws(CommandError) {
        executeCalled = true
        lastPayload = payload
        executeCallCount += 1

        if let errorToThrow {
            throw errorToThrow
        }
    }
}
