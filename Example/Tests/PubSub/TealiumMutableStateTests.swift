//
//  TealiumMutableStateTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class TealiumMutableStateTests: XCTestCase {

    let mutableState = TealiumMutableState(0)

    func test_value_changes_emit_new_updates() {
        let stateChanged = expectation(description: "State changed")
        stateChanged.expectedFulfillmentCount = 3
        var count = 1
        _ = mutableState.updates().subscribe { element in
            XCTAssertEqual(count, element)
            count += 1
            stateChanged.fulfill()
        }
        mutableState.value = 1
        mutableState.value = 2
        mutableState.value = 3
        waitForExpectations(timeout: 1.0)
    }

    func test_value_returns_latest_provided_value() {
        XCTAssertEqual(mutableState.value, 0)
        mutableState.value = 1
        mutableState.value = 2
        mutableState.value = 3
        XCTAssertEqual(mutableState.value, 3)
    }

    func test_asObservable_emits_current_value_and_all_updates() {
        let stateChanged = expectation(description: "State changed")
        stateChanged.expectedFulfillmentCount = 4
        var count = 0
        _ = mutableState.asObservable().subscribe { element in
            XCTAssertEqual(count, element)
            count += 1
            stateChanged.fulfill()
        }
        mutableState.value = 1
        mutableState.value = 2
        mutableState.value = 3
        waitForExpectations(timeout: 1.0)
    }

    func test_mutateIfChanged_only_emits_new_updates_if_changed() {
        let stateChanged = expectation(description: "State changed")
        stateChanged.expectedFulfillmentCount = 2
        var count = 1
        _ = mutableState.updates().subscribe { element in
            XCTAssertEqual(count, element)
            count += 1
            stateChanged.fulfill()
        }
        mutableState.mutateIfChanged(1)
        mutableState.mutateIfChanged(1)
        mutableState.mutateIfChanged(1)
        mutableState.mutateIfChanged(2)
        waitForExpectations(timeout: 1.0)
    }
}
