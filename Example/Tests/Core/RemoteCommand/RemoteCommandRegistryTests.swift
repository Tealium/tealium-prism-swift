//
//  RemoteCommandRegistryTests.swift
//  TealiumPrismCoreTests
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class RemoteCommandRegistryTests: XCTestCase {

    var registry: RemoteCommandRegistry!

    override func setUp() {
        super.setUp()
        registry = RemoteCommandRegistry()
    }

    // MARK: - Registration Tests

    func test_register_single_command() {
        let command = MockRemoteCommand(name: "test")
        registry.register(command)

        let payload: DataObject = [:]

        XCTAssertNoThrow(try registry.execute(commandName: "test", payload: payload))
        XCTAssertTrue(command.executeCalled)
    }

    func test_register_multiple_commands() {
        let command1 = MockRemoteCommand(name: "command1")
        let command2 = MockRemoteCommand(name: "command2")
        let command3 = MockRemoteCommand(name: "command3")

        registry.registerAll([command1, command2, command3])

        let payload: DataObject = [:]

        XCTAssertNoThrow(try registry.execute(commandName: "command1", payload: payload))
        XCTAssertNoThrow(try registry.execute(commandName: "command2", payload: payload))
        XCTAssertNoThrow(try registry.execute(commandName: "command3", payload: payload))

        XCTAssertTrue(command1.executeCalled)
        XCTAssertTrue(command2.executeCalled)
        XCTAssertTrue(command3.executeCalled)
    }

    func test_register_overwrites_existing_command() {
        let originalCommand = MockRemoteCommand(name: "test")
        let newCommand = MockRemoteCommand(name: "test")

        registry.register(originalCommand)
        registry.register(newCommand)

        let payload: DataObject = [:]
        XCTAssertNoThrow(try registry.execute(commandName: "test", payload: payload))

        XCTAssertFalse(originalCommand.executeCalled)
        XCTAssertTrue(newCommand.executeCalled)
    }

    // MARK: - Execution Tests

    func test_execute_unknown_command_throws_error() {
        let payload: DataObject = [:]

        XCTAssertThrowsError(try registry.execute(commandName: "unknown", payload: payload)) { error in
            guard let commandError = error as? RemoteCommandError,
                  case .commandNotFound(let name) = commandError else {
                XCTFail("Expected commandNotFound but got \(error)")
                return
            }
            XCTAssertEqual(name, "unknown")
        }
    }

    func test_execute_normalizes_command_name_to_lowercase() {
        let command = MockRemoteCommand(name: "test")
        registry.register(command)

        let payload: DataObject = [:]

        XCTAssertNoThrow(try registry.execute(commandName: "TEST", payload: payload))
        XCTAssertNoThrow(try registry.execute(commandName: "Test", payload: payload))
        XCTAssertNoThrow(try registry.execute(commandName: "TeSt", payload: payload))
    }

    func test_execute_trims_whitespace_from_command_name() {
        let command = MockRemoteCommand(name: "test")
        registry.register(command)

        let payload: DataObject = [:]

        XCTAssertNoThrow(try registry.execute(commandName: "  test  ", payload: payload))
        XCTAssertNoThrow(try registry.execute(commandName: "\ttest\t", payload: payload))
    }

    func test_execute_passes_payload_to_command() {
        let command = MockRemoteCommand(name: "test")
        registry.register(command)

        let payload: DataObject = ["key": "value", "number": 42]

        XCTAssertNoThrow(try registry.execute(commandName: "test", payload: payload))

        XCTAssertEqual(command.lastPayload, payload)
    }

    func test_execute_propagates_command_error() {
        let failureCommand = MockRemoteCommand(name: "failure", errorToThrow: .missingParameter("test_param"))

        registry.register(failureCommand)

        let payload: DataObject = [:]

        XCTAssertThrowsError(try registry.execute(commandName: "failure", payload: payload)) { error in
            XCTAssert(error is RemoteCommandError)
        }
    }
}
