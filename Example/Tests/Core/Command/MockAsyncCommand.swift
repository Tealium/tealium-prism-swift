//
//  MockAsyncCommand.swift
//  TealiumPrismCoreTests
//
//  Created by Sebastian Krajna on 26/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation
@testable import TealiumPrism

/// Mock implementation of `Command` for testing async command execution.
/// Defaults to completing immediately but can be controlled via `delayBlock` to simulate async work.
class MockAsyncCommand: Command {

    let name: String
    var executeCalled = false
    var executeCallCount = 0
    var lastPayload: DataObject?
    let errorToThrow: CommandError?

    /// Controls when the command calls completion. Defaults to immediate execution.
    /// Override in tests to defer completion: `command.delayBlock = { block in delayed = block }`.
    var delayBlock: (@escaping () -> Void) -> Void = { block in block() }

    init(name: String, errorToThrow: CommandError? = nil) {
        self.name = name
        self.errorToThrow = errorToThrow
    }

    func execute(payload: DataObject, completion: @escaping (CommandError?) -> Void) -> Disposable {
        executeCalled = true
        executeCallCount += 1
        lastPayload = payload
        let subscription = Subscription { }
        let error = errorToThrow
        delayBlock {
            guard !subscription.isDisposed else { return }
            completion(error)
        }
        return subscription
    }
}
