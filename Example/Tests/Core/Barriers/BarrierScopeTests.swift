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
    let converter = BarrierScope.converter

    func test_barrier_scope_toDataInput_all() {
        let scope = BarrierScope.all
        XCTAssertEqual(scope.toDataInput() as? String, "all")
    }

    func test_barrier_scope_toDataInput_dispatchers() {
        let scope = BarrierScope.dispatchers(["a", "b"])
        XCTAssertEqual(scope.toDataInput() as? [DataInput] as? [String], ["a", "b"])
    }

    func test_converter_all_lowercase_returns_all() {
        XCTAssertEqual(converter.convert(dataItem: DataItem(value: "all")), .all)
    }

    func test_converter_all_uppercase_returns_all() {
        XCTAssertEqual(converter.convert(dataItem: DataItem(value: "ALL")), .all)
    }

    func test_converter_all_mixed_case_returns_all() {
        XCTAssertEqual(converter.convert(dataItem: DataItem(value: "All")), .all)
    }

    func test_converter_unknown_string_returns_nil() {
        XCTAssertNil(converter.convert(dataItem: DataItem(value: "TestDispatcher")))
        XCTAssertNil(converter.convert(dataItem: DataItem(value: "collect")))
    }

    func test_converter_array_of_ids_returns_dispatchers() {
        let ids = ["collect", "trace"] as [DataInput]
        XCTAssertEqual(converter.convert(dataItem: DataItem(value: ids)), .dispatchers(["collect", "trace"]))
    }

    func test_converter_empty_array_returns_dispatchers_with_empty_ids() {
        XCTAssertEqual(converter.convert(dataItem: DataItem(value: [] as [DataInput])), .dispatchers([]))
    }

    func test_barrier_scope_matches_all() {
        XCTAssertTrue(BarrierScope.all.matches(dispatcherId: "anything"))
        XCTAssertTrue(BarrierScope.all.matches(dispatcherId: ""))
    }

    func test_barrier_scope_matches_dispatchers() {
        let scope = BarrierScope.dispatchers(["collect", "trace"])
        XCTAssertTrue(scope.matches(dispatcherId: "collect"))
        XCTAssertTrue(scope.matches(dispatcherId: "trace"))
        XCTAssertFalse(scope.matches(dispatcherId: "other"))
    }

    func test_barrier_scope_matches_empty_dispatchers() {
        XCTAssertFalse(BarrierScope.dispatchers([]).matches(dispatcherId: "collect"))
    }

    func test_converter_non_string_non_array_returns_nil() {
        XCTAssertNil(converter.convert(dataItem: DataItem(value: 42)))
    }
}
