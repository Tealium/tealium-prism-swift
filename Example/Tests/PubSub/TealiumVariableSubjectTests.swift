//
//  TealiumVariableSubjectTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import XCTest

final class TealiumVariableSubjectTests: XCTestCase {

    let variableSubject = TealiumVariableSubject(0)

    func test_value_changes_emit_new_updates() {
        let stateChanged = expectation(description: "State changed")
        stateChanged.expectedFulfillmentCount = 3
        var count = 1
        _ = variableSubject.updates().subscribe { element in
            XCTAssertEqual(count, element)
            count += 1
            stateChanged.fulfill()
        }
        variableSubject.value = 1
        variableSubject.value = 2
        variableSubject.value = 3
        waitForExpectations(timeout: 1.0)
    }

    func test_value_returns_latest_provided_value() {
        XCTAssertEqual(variableSubject.value, 0)
        variableSubject.value = 1
        variableSubject.value = 2
        variableSubject.value = 3
        XCTAssertEqual(variableSubject.value, 3)
    }

    func test_asObservable_emits_current_value_and_all_updates() {
        let stateChanged = expectation(description: "State changed")
        stateChanged.expectedFulfillmentCount = 4
        var count = 0
        _ = variableSubject.asObservable().subscribe { element in
            XCTAssertEqual(count, element)
            count += 1
            stateChanged.fulfill()
        }
        variableSubject.value = 1
        variableSubject.value = 2
        variableSubject.value = 3
        waitForExpectations(timeout: 1.0)
    }

    func test_mutateIfChanged_only_emits_new_updates_if_changed() {
        let stateChanged = expectation(description: "State changed")
        stateChanged.expectedFulfillmentCount = 2
        var count = 1
        _ = variableSubject.updates().subscribe { element in
            XCTAssertEqual(count, element)
            count += 1
            stateChanged.fulfill()
        }
        variableSubject.publishIfChanged(1)
        variableSubject.publishIfChanged(1)
        variableSubject.publishIfChanged(1)
        variableSubject.publishIfChanged(2)
        waitForExpectations(timeout: 1.0)
    }

    func test_mutate_array_emits_new_update() {
        let variableSubject = TealiumVariableSubject([1, 2, 3])
        let updated = expectation(description: "Update arrives")
        _ = variableSubject.updates().subscribe { result in
            updated.fulfill()
            XCTAssertEqual(result, [1, 2, 3, 4])
        }
        variableSubject.value.append(4)
        XCTAssertEqual(variableSubject.value, [1, 2, 3, 4])
        waitForExpectations(timeout: 1.0)
    }

    func test_map_emits_updates() {
        let multipleValuesEmitted = expectation(description: "Multiple values are emitted")
        multipleValuesEmitted.expectedFulfillmentCount = 5
        var count = 0
        _ = variableSubject.toStatefulObservable()
            .map { $0 + 1 }
            .subscribe { value in
                count += 1
                XCTAssertEqual(count, value)
                multipleValuesEmitted.fulfill()
            }
        variableSubject.value = 1
        variableSubject.value = 2
        variableSubject.value = 3
        variableSubject.value = 4
        waitForExpectations(timeout: 1.0)
    }
}
