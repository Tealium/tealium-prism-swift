//
//  CommandDispatcherTests.swift
//  TealiumPrismCoreTests
//
//  Created by Sebastian Krajna on 27/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class CommandDispatcherTests: XCTestCase {

    let queue = TealiumQueue.main

    // MARK: - Sync Command Tests

    func test_dispatch_executes_sync_command() {
        let command = MockSyncCommand(name: "logevent")
        let dispatcher = CommandDispatcher(
            id: "test", version: "1.0", commands: [command], logCategory: "test", queue: queue, logger: nil
        )
        let completed = expectation(description: "dispatch completed")

        let dispatch = Dispatch(name: "event", data: [TealiumDataKey.commandName: "logevent"])

        _ = dispatcher.dispatch([dispatch]) { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            completed.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertTrue(command.executeCalled)
    }

    func test_dispatch_executes_multiple_commands() {
        let command1 = MockSyncCommand(name: "cmd1")
        let command2 = MockSyncCommand(name: "cmd2")
        let dispatcher = CommandDispatcher(
            id: "test", version: "1.0", commands: [command1, command2], logCategory: "test", queue: queue, logger: nil
        )
        let completed = expectation(description: "dispatch completed")

        let dispatch = Dispatch(name: "event", data: [TealiumDataKey.commandName: ["cmd1", "cmd2"]])

        _ = dispatcher.dispatch([dispatch]) { _ in
            completed.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertTrue(command1.executeCalled)
        XCTAssertTrue(command2.executeCalled)
    }

    func test_dispatch_with_no_commands_still_completes() {
        let dispatcher = CommandDispatcher(
            id: "test", version: "1.0", commands: [], logCategory: "test", queue: queue, logger: nil
        )
        let completed = expectation(description: "dispatch completed")

        let dispatch = Dispatch(name: "event")

        _ = dispatcher.dispatch([dispatch]) { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            completed.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func test_dispatch_command_error_continues_to_next_command() {
        let failingCommand = MockSyncCommand(name: "fail", errorToThrow: .missingParameter("p"))
        let successCommand = MockSyncCommand(name: "ok")
        let dispatcher = CommandDispatcher(
            id: "test", version: "1.0", commands: [failingCommand, successCommand], logCategory: "test", queue: queue, logger: nil
        )
        let completed = expectation(description: "dispatch completed")

        let dispatch = Dispatch(name: "event", data: [TealiumDataKey.commandName: ["fail", "ok"]])

        _ = dispatcher.dispatch([dispatch]) { _ in
            completed.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertTrue(failingCommand.executeCalled)
        XCTAssertTrue(successCommand.executeCalled)
    }

    func test_dispatch_passes_payload_to_commands() {
        let command = MockSyncCommand(name: "test")
        let dispatcher = CommandDispatcher(
            id: "test", version: "1.0", commands: [command], logCategory: "test", queue: queue, logger: nil
        )
        let completed = expectation(description: "dispatch completed")

        let dispatch = Dispatch(name: "event", data: [TealiumDataKey.commandName: "test"])

        _ = dispatcher.dispatch([dispatch]) { _ in
            completed.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(command.lastPayload, dispatch.payload)
    }

    // MARK: - Multiple Dispatch Tests

    func test_dispatch_calls_completion_for_each_dispatch() {
        let command = MockSyncCommand(name: "test")
        let dispatcher = CommandDispatcher(
            id: "test", version: "1.0", commands: [command], logCategory: "test", queue: queue, logger: nil
        )
        let completed = expectation(description: "dispatch completed")
        completed.expectedFulfillmentCount = 3

        let dispatch1 = Dispatch(name: "event1", data: [TealiumDataKey.commandName: "test"])
        let dispatch2 = Dispatch(name: "event2", data: [TealiumDataKey.commandName: "test"])
        let dispatch3 = Dispatch(name: "event3", data: [TealiumDataKey.commandName: "test"])

        _ = dispatcher.dispatch([dispatch1, dispatch2, dispatch3]) { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            completed.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(command.executeCallCount, 3)
    }

    // MARK: - Async Command Tests

    func test_dispatch_async_command_completes_after_command_finishes() {
        let command = MockAsyncCommand(name: "async")
        let dispatcher = CommandDispatcher(
            id: "test", version: "1.0", commands: [command], logCategory: "test", queue: queue, logger: nil
        )
        let completed = expectation(description: "dispatch completed")

        var delayed: (() -> Void)?
        command.delayBlock = { block in delayed = block }

        let dispatch = Dispatch(name: "event", data: [TealiumDataKey.commandName: "async"])

        _ = dispatcher.dispatch([dispatch]) { _ in
            completed.fulfill()
        }

        delayed?()
        waitForExpectations(timeout: 1)
        XCTAssertTrue(command.executeCalled)
    }

    // MARK: - Cancellation Tests

    func test_dispose_prevents_completion() {
        let command = MockAsyncCommand(name: "async")
        let dispatcher = CommandDispatcher(
            id: "test", version: "1.0", commands: [command], logCategory: "test", queue: queue, logger: nil
        )
        let completionCalled = expectation(description: "completion called")
        completionCalled.isInverted = true

        let dispatch = Dispatch(name: "event", data: [TealiumDataKey.commandName: "async"])

        var delayed: (() -> Void)?
        command.delayBlock = { block in delayed = block }

        let disposable = dispatcher.dispatch([dispatch]) { _ in
            completionCalled.fulfill()
        }

        disposable.dispose()
        // Even if the delayed block fires, the dispatcher should not call completion.
        delayed?()
        waitForExpectations(timeout: 0.2)
    }
}
