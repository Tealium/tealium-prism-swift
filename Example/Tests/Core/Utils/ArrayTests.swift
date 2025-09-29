//
//  ArrayTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ArrayTests: XCTestCase {
    var array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

    func test_partitioned_returns_accepted_elements_first() {
        let (first, second) = array.partitioned(by: { _ in true })
        XCTAssertEqual(first, array)
        XCTAssertTrue(second.isEmpty)
    }

    func test_partitioned_returns_discarded_elements_first() {
        let (first, second) = array.partitioned(by: { _ in false })
        XCTAssertTrue(first.isEmpty)
        XCTAssertEqual(second, array)
    }

    func test_partitioned_returns_elements_partitioned_according_to_provided_closure() {
        let (even, odd) = array.partitioned(by: { $0 % 2 == 0 })
        XCTAssertEqual(even, [0, 2, 4, 6, 8])
        XCTAssertEqual(odd, [1, 3, 5, 7, 9])
    }

    func test_removingDuplicates_removes_duplicates_while_keeping_order() {
        let array = [1, 2, 3, 4, 5, 5, 8, 5]
        XCTAssertEqual(array.removingDuplicates(by: \.self), [1, 2, 3, 4, 5, 8])
    }

    func test_diff_returns_items_missing_from_other_array() {
        XCTAssertEqual(array.diff([1, 3, 5, 7, 9], by: \.self), [0, 2, 4, 6, 8])
    }

    func test_removeFirst_removes_first_item_matching_closure() {
        let removed = array.removeFirst(where: { $0 == 2 })
        XCTAssertEqual(removed, 2)
        XCTAssertEqual(array, [0, 1, 3, 4, 5, 6, 7, 8, 9])
    }

    func test_removeFirst_only_the_first_item_matching_closure() {
        let removed = array.removeFirst(where: { $0 > 1 })
        XCTAssertEqual(removed, 2)
        XCTAssertEqual(array, [0, 1, 3, 4, 5, 6, 7, 8, 9])
    }
}
