//
//  Array+DataItemInternalsTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 31/08/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ArrayDataItemInternalsTests: XCTestCase {

    // MARK: - subscript(safe:) setter

    func test_safe_setter_overwrites_existing_middle_index_without_growing() {
        var array: [DataItem] = [DataItem(value: "a"), DataItem(value: "b"), DataItem(value: "c")]
        array[safe: 1] = DataItem(value: "X")
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(DataItem(converting: array).getArray(), ["a", "X", "c"])
    }

    func test_safe_setter_overwrites_first_index() {
        var array: [DataItem] = [DataItem(value: "a"), DataItem(value: "b"), DataItem(value: "c")]
        array[safe: 0] = DataItem(value: "NEW")
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(DataItem(converting: array).getArray(), ["NEW", "b", "c"])
    }

    func test_safe_setter_at_count_boundary_appends_single_element() {
        var array: [DataItem] = [DataItem(value: "a"), DataItem(value: "b")]
        array[safe: 2] = DataItem(value: "c")
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(DataItem(converting: array).getArray(), ["a", "b", "c"])
    }

    func test_safe_setter_past_count_pads_with_null() {
        var array: [DataItem] = [DataItem(value: "a")]
        array[safe: 3] = DataItem(value: "X")
        XCTAssertEqual(array.count, 4)
        XCTAssertEqual(DataItem(converting: array).getArray(), ["a", nil, nil, "X"])
    }

    func test_safe_setter_with_nil_stores_null_in_place() {
        var array: [DataItem] = [DataItem(value: "a"), DataItem(value: "b")]
        array[safe: 0] = nil
        XCTAssertEqual(array.count, 2)
        XCTAssertEqual(DataItem(converting: array).getArray(), [nil, "b"])
    }

    func test_safe_setter_with_negative_index_is_ignored() {
        var array: [DataItem] = [DataItem(value: "a"), DataItem(value: "b")]
        array[safe: -1] = DataItem(value: "X")
        XCTAssertEqual(array.count, 2)
        XCTAssertEqual(DataItem(converting: array).getArray(), ["a", "b"])
    }

    // MARK: - subscript(safe:) getter

    func test_safe_getter_returns_nil_for_out_of_range_index() {
        let array: [DataItem] = [DataItem(value: "a"), DataItem(value: "b")]
        XCTAssertNil(array[safe: 2])
    }

    func test_safe_getter_returns_value_for_in_range_index() {
        let array: [DataItem] = [DataItem(value: "a"), DataItem(value: "b")]
        XCTAssertEqual(array[safe: 1]?.get(), "b")
    }
}
