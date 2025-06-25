//
//  ArrayTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ArrayTests: XCTestCase {
    let array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

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
}
