//
//  BarrierScopeTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 24/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class BarrierScopeTests: XCTestCase {

    func test_barrier_scope_rawValue() {
        XCTAssertEqual(BarrierScope.all.rawValue, "all")
        XCTAssertEqual(BarrierScope.dispatcher(id: "test_dispatcher").rawValue, "test_dispatcher")
    }

    func test_barrier_scope_init_from_rawValue() {
        XCTAssertEqual(BarrierScope(rawValue: "all"), .all)
        XCTAssertEqual(BarrierScope(rawValue: "ALL"), .all) // Case insensitive
        XCTAssertEqual(BarrierScope(rawValue: "All"), .all) // Case insensitive
        XCTAssertEqual(BarrierScope(rawValue: "TestDispatcher"), .dispatcher(id: "TestDispatcher"))
        XCTAssertNotEqual(BarrierScope(rawValue: "COLLECT"), .dispatcher(id: "collect")) // Case-sensitive
    }
}
