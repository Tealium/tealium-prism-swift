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

    func test_diff_by_comparator_keeps_the_elements_no_element_of_other_matches() {
        let boxA = Box(id: "a")
        let boxB = Box(id: "b")
        let boxC = Box(id: "c")
        let result = [boxA, boxB, boxC].diff([boxB], by: ===)
        XCTAssertTrue(result.elementsEqual([boxA, boxC], by: ===))
    }

    func test_diff_by_comparator_returns_all_elements_when_other_is_empty() {
        let boxA = Box(id: "a")
        let boxB = Box(id: "b")
        let result = [boxA, boxB].diff([], by: ===)
        XCTAssertTrue(result.elementsEqual([boxA, boxB], by: ===))
    }

    func test_diff_by_comparator_returns_empty_when_every_element_is_matched() {
        let boxA = Box(id: "a")
        let boxB = Box(id: "b")
        let result = [boxA, boxB].diff([boxA, boxB], by: ===)
        XCTAssertTrue(result.isEmpty)
    }

    func test_diff_by_comparator_distinguishes_instances_with_the_same_key() {
        let boxA = Box(id: "a")
        let boxATwin = Box(id: "a")
        let byIdentity = [boxA].diff([boxATwin], by: ===)
        XCTAssertTrue(byIdentity.elementsEqual([boxA], by: ===))

        let byId = [boxA].diff([boxATwin], by: { $0.id == $1.id })
        XCTAssertTrue(byId.isEmpty)
    }

    func test_diff_by_comparator_calls_comparator_with_parameters_in_order() {
        let boxA = Box(id: "a")
        let boxATwin = Box(id: "a")
        let byIdentity = [boxA].diff([boxATwin]) { first, second in
            XCTAssertIdentical(boxA, first)
            XCTAssertIdentical(boxATwin, second)
            return first === second
        }
        XCTAssertTrue(byIdentity.elementsEqual([boxA], by: ===))
    }

    func test_diff_by_keyPath_delegates_to_the_comparator_overload() {
        let boxA = Box(id: "a")
        let boxATwin = Box(id: "a")
        let boxB = Box(id: "b")
        let byKeyPath = [boxA, boxB].diff([boxATwin], by: \.id)
        let byComparator = [boxA, boxB].diff([boxATwin], by: { $0.id == $1.id })
        XCTAssertTrue(byKeyPath.elementsEqual(byComparator, by: ===))
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

private final class Box {
    let id: String

    init(id: String) {
        self.id = id
    }
}
