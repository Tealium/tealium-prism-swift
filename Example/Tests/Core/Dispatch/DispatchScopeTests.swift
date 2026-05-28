//
//  DispatchScopeTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 24/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DispatchScopeTests: XCTestCase {

    func test_dispatch_scope_rawValue() {
        XCTAssertEqual(DispatchScope.afterCollectors.rawValue, "aftercollectors")
        XCTAssertEqual(DispatchScope.dispatcher(id: "test_dispatcher").rawValue, "test_dispatcher")
    }

    func test_dispatch_scope_init_from_rawValue() {
        XCTAssertEqual(DispatchScope(rawValue: "aftercollectors"), .afterCollectors)
        XCTAssertEqual(DispatchScope(rawValue: "AFTERCOLLECTORS"), .afterCollectors) // Case insensitive
        XCTAssertEqual(DispatchScope(rawValue: "AfterCollectors"), .afterCollectors) // Case insensitive
        XCTAssertEqual(DispatchScope(rawValue: "TestDispatcher"), .dispatcher(id: "TestDispatcher"))
        XCTAssertNotEqual(DispatchScope(rawValue: "COLLECT"), .dispatcher(id: "collect")) // Case-sensitive
    }
}
