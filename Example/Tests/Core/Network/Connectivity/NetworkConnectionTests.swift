//
//  NetworkConnectionTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 26/02/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//
@testable import TealiumSwift
import XCTest

final class NetworkConnectionTests: XCTestCase {
    func test_toString_returnsExpectedValue() {
        XCTAssertEqual(NetworkConnection.connected(.wifi).toString(), "wifi")
        XCTAssertEqual(NetworkConnection.connected(.cellular).toString(), "cellular")
        XCTAssertEqual(NetworkConnection.connected(.ethernet).toString(), "ethernet")
        XCTAssertEqual(NetworkConnection.notConnected.toString(), "none")
        XCTAssertEqual(NetworkConnection.unknown.toString(), "unknown")
    }
}
