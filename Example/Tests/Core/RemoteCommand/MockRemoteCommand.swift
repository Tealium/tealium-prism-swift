//
//  MockRemoteCommand.swift
//  TealiumPrismCoreTests
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation
@testable import TealiumPrism

/// Mock implementation of RemoteCommandProtocol for testing command execution.
/// Tracks execution calls and can be configured to succeed or throw an error.
class MockRemoteCommand: RemoteCommandProtocol {

    let name: String
    let errorToThrow: RemoteCommandError?

    var executeCalled = false
    var lastPayload: DataObject?
    var executeCallCount = 0

    init(name: String, errorToThrow: RemoteCommandError? = nil) {
        self.name = name
        self.errorToThrow = errorToThrow
    }

    func execute(payload: DataObject) throws(RemoteCommandError) {
        executeCalled = true
        lastPayload = payload
        executeCallCount += 1

        if let errorToThrow {
            throw errorToThrow
        }
    }
}
