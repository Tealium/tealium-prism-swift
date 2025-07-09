//
//  DisposableItemListTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 12/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DisposableItemListTests: XCTestCase {

    let observerList = DisposableItemList<Int>()

    func test_insert_adds_observer_to_list() {
        _ = observerList.insert(1)
        XCTAssertTrue(observerList.ordered().contains(1), "List does not contain the item 1")
    }

    func test_orderedObservers_returns_all_the_observers_in_order() {
        _ = observerList.insert(1)
        _ = observerList.insert(2)
        _ = observerList.insert(3)
        _ = observerList.insert(4)
        _ = observerList.insert(5)
        XCTAssertEqual(observerList.ordered(), [1, 2, 3, 4, 5])
    }

    func test_dispose_subscription_removes_the_subscription() {
        let subscription = observerList.insert(1)
        XCTAssertTrue(observerList.ordered().contains(1), "List does not contain the item 1")
        subscription.dispose()
        XCTAssertFalse(observerList.ordered().contains(1), "List contains the item 1")
    }

    func test_dispose_subscription_leaves_other_observers_in_the_list() {
        _ = observerList.insert(1)
        let subscription = observerList.insert(2)
        _ = observerList.insert(3)
        XCTAssertTrue(observerList.ordered().contains(1), "List does not contain the item 1")
        XCTAssertTrue(observerList.ordered().contains(3), "List does not contain the item 3")
        subscription.dispose()
        XCTAssertTrue(observerList.ordered().contains(1), "List does not contain the item 1")
        XCTAssertTrue(observerList.ordered().contains(3), "List does not contain the item 3")
    }

    func test_dispose_doesnt_cause_reentrancy_crash() {
        let observerList = DisposableItemList<Any>()
        let first = observerList.insert(1)
        let second = observerList.insert(DeinitTester {
            // This crashes if deinit causes a reentrancy avoided by fixing removeFirst
            first.dispose()
        })
        second.dispose()
    }
}
