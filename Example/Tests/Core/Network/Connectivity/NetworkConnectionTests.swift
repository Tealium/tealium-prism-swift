//
//  NetworkConnectionTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 26/02/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//
@testable import TealiumPrism
import XCTest

final class NetworkConnectionTests: XCTestCase {
    func test_toString_returns_expected_value() {
        XCTAssertEqual(NetworkConnection.connected(.wifi).toString(), "wifi")
        XCTAssertEqual(NetworkConnection.connected(.cellular).toString(), "cellular")
        XCTAssertEqual(NetworkConnection.connected(.ethernet).toString(), "ethernet")
        XCTAssertEqual(NetworkConnection.notConnected.toString(), "none")
        XCTAssertEqual(NetworkConnection.unknown.toString(), "unknown")
    }

    func test_isConnected_returns_true_for_connected() {
        XCTAssertTrue(NetworkConnection.connected(.wifi).isConnected)
        XCTAssertTrue(NetworkConnection.connected(.cellular).isConnected)
        XCTAssertTrue(NetworkConnection.connected(.ethernet).isConnected)
    }

    func test_isConnected_returns_false_for_notConnected() {
        XCTAssertFalse(NetworkConnection.notConnected.isConnected)
    }

    func test_isConnected_returns_false_for_unknown() {
        XCTAssertFalse(NetworkConnection.unknown.isConnected)
    }

    func test_type_returns_correct_connection_type() {
        XCTAssertEqual(NetworkConnection.connected(.wifi).type, .wifi)
        XCTAssertEqual(NetworkConnection.connected(.cellular).type, .cellular)
        XCTAssertEqual(NetworkConnection.connected(.ethernet).type, .ethernet)
        XCTAssertNil(NetworkConnection.notConnected.type)
        XCTAssertNil(NetworkConnection.unknown.type)
    }
}
