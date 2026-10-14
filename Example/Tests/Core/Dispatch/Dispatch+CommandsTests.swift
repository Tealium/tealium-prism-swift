//
//  Dispatch+CommandsTests.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 19/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DispatchCommandsTests: XCTestCase {

    func test_getCommands_returns_single_command_as_array() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.commandName: "logevent"
        ])
        XCTAssertEqual(dispatch.getCommands(), ["logevent"])
    }

    func test_getCommands_returns_array_of_commands() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.commandName: ["logevent", "setuserid"]
        ])
        XCTAssertEqual(dispatch.getCommands(), ["logevent", "setuserid"])
    }

    func test_getCommands_returns_empty_array_when_no_command_name() {
        let dispatch = Dispatch(name: "event")
        XCTAssertEqual(dispatch.getCommands(), [])
    }

    func test_getCommands_removes_exact_duplicates() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.commandName: ["logevent", "setuserid", "logevent"]
        ])
        XCTAssertEqual(dispatch.getCommands(), ["logevent", "setuserid"])
    }

    func test_getCommands_removes_case_and_whitespace_variants_keeping_the_first() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.commandName: [" LogEvent ", "setuserid", "logevent", "SETUSERID", "other"]
        ])
        XCTAssertEqual(dispatch.getCommands(), [" LogEvent ", "setuserid", "other"])
    }

    func test_getCommands_preserves_order() {
        let dispatch = Dispatch(name: "event", data: [
            TealiumDataKey.commandName: ["c", "a", "b", "a", "c"]
        ])
        XCTAssertEqual(dispatch.getCommands(), ["c", "a", "b"])
    }
}
