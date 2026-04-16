//
//  SyncCommandTests.swift
//  TealiumPrismCoreTests
//
//  Created by Sebastian Krajna on 26/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SyncCommandTests: XCTestCase {

    func test_execute_calls_sync_overload() {
        let command = MockSyncCommand(name: "test")
        let payload: DataObject = ["key": "value"]

        _ = command.execute(payload: payload) { _ in }

        XCTAssertTrue(command.executeCalled)
        XCTAssertEqual(command.lastPayload, payload)
    }

    func test_execute_completion_nil_on_success() {
        let command = MockSyncCommand(name: "test")

        var receivedError: CommandError?
        _ = command.execute(payload: [:]) { receivedError = $0 }

        XCTAssertNil(receivedError)
    }

    func test_execute_completion_receives_error_on_throw() {
        let command = MockSyncCommand(name: "test", errorToThrow: .missingParameter("param"))

        var receivedError: CommandError?
        _ = command.execute(payload: [:]) { receivedError = $0 }

        guard case .missingParameter(let name) = receivedError else {
            XCTFail("Expected missingParameter but got \(String(describing: receivedError))")
            return
        }
        XCTAssertEqual(name, "param")
    }

    func test_execute_returns_disposed_disposable() {
        let command = MockSyncCommand(name: "test")

        let disposable = command.execute(payload: [:]) { _ in }

        XCTAssertTrue(disposable.isDisposed)
    }

    func test_execute_increments_call_count() {
        let command = MockSyncCommand(name: "test")

        _ = command.execute(payload: [:]) { _ in }
        _ = command.execute(payload: [:]) { _ in }
        _ = command.execute(payload: [:]) { _ in }

        XCTAssertEqual(command.executeCallCount, 3)
    }
}
