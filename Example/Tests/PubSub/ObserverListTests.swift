//
//  ObserverListTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 12/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ObserverListTests: XCTestCase {

    let observerList = ObserverList<Int>()

    func test_insert_adds_observer_to_list() {
        _ = observerList.insert(1)
        XCTAssertTrue(observerList.orderedObservers().contains(1), "Observer does not contain the item 1")
    }

    func test_orderedObservers_returns_all_the_observers_in_order() {
        _ = observerList.insert(1)
        _ = observerList.insert(2)
        _ = observerList.insert(3)
        _ = observerList.insert(4)
        _ = observerList.insert(5)
        XCTAssertEqual(observerList.orderedObservers(), [1, 2, 3, 4, 5])
    }

    func test_dispose_subscription_removes_the_subscription() {
        let subscription = observerList.insert(1)
        XCTAssertTrue(observerList.orderedObservers().contains(1), "Observer does not contain the item 1")
        subscription.dispose()
        XCTAssertFalse(observerList.orderedObservers().contains(1), "Observer contains the item 1")
    }

    func test_dispose_subscription_leaves_other_observers_in_the_list() {
        _ = observerList.insert(1)
        let subscription = observerList.insert(2)
        _ = observerList.insert(3)
        XCTAssertTrue(observerList.orderedObservers().contains(1), "Observer does not contain the item 1")
        XCTAssertTrue(observerList.orderedObservers().contains(3), "Observer does not contain the item 3")
        subscription.dispose()
        XCTAssertTrue(observerList.orderedObservers().contains(1), "Observer does not contain the item 1")
        XCTAssertTrue(observerList.orderedObservers().contains(3), "Observer does not contain the item 3")
    }
}
