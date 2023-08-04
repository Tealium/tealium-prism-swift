//
//  EmpiricalConnectivityTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class EmpiricalConnectivityTests: XCTestCase {
    let empiricalConnectivity = EmpiricalConnectivity()

    func test_connectivity_starts_with_assuming_available() {
        let connectionAvailable = expectation(description: "Empirical connection available")
        empiricalConnectivity.onEmpiricalConnectionAvailable
            .subscribeOnce { available in
                XCTAssertTrue(available)
                connectionAvailable.fulfill()
            }
        waitForExpectations(timeout: 1.0)
    }

    func test_connectivity_becomes_unavailable_on_connection_failure() {
        let connectionNotAvailable = expectation(description: "Empirical connection is not available")
        empiricalConnectivity.connectionFail()
        empiricalConnectivity.onEmpiricalConnectionAvailable
            .subscribeOnce { available in
                XCTAssertFalse(available)
                connectionNotAvailable.fulfill()
            }
        waitForExpectations(timeout: 1.0)
    }

    func test_connectivity_returns_available_on_connection_success() {
        let connectionAvailable = expectation(description: "Empirical connection is available")
        empiricalConnectivity.connectionFail()
        empiricalConnectivity.connectionSuccess()
        empiricalConnectivity.onEmpiricalConnectionAvailable
            .subscribeOnce { available in
                XCTAssertTrue(available)
                connectionAvailable.fulfill()
            }
        waitForExpectations(timeout: 1.0)
    }

    func test_connectivity_returns_available_on_timeout() {
        let connectionAvailableChange = expectation(description: "Connection is changed")
        connectionAvailableChange.expectedFulfillmentCount = 2
        let empiricalConnectivity = EmpiricalConnectivity(debouncer: MockInstantDebouncer(queue: .main))
        empiricalConnectivity.connectionFail()

        var firstEventReturned = false
        _ = empiricalConnectivity.onEmpiricalConnectionAvailable
            .subscribe { available in
                if firstEventReturned {
                    XCTAssertTrue(available)
                } else {
                    firstEventReturned = true
                    XCTAssertFalse(available)
                }
                connectionAvailableChange.fulfill()
            }
        waitForExpectations(timeout: 1.0)
    }

    func test_connection_fail_without_success_increases_number_of_failures() {
        let connectionAvailable = expectation(description: "Connection returns Available")
        connectionAvailable.assertForOverFulfill = false
        connectionAvailable.expectedFulfillmentCount = 5
        let empiricalConnectivity = EmpiricalConnectivity(debouncer: MockInstantDebouncer(queue: .main))
        var numberOfFailures = 0
        func fail() {
            empiricalConnectivity.connectionFail()
            numberOfFailures += 1
        }
        fail()
        _ = empiricalConnectivity.onEmpiricalConnectionAvailable
            .subscribe { available in
                if available {
                    XCTAssertEqual(empiricalConnectivity.numberOfFailedConsecutiveTimeouts, numberOfFailures)
                    connectionAvailable.fulfill()
                    fail()
                }
            }
        waitForExpectations(timeout: 3.0)
    }

    func test_connection_success_resets_number_of_failures() {
        let connectionAvailable = expectation(description: "Connection returns Available")
        let empiricalConnectivity = EmpiricalConnectivity(debouncer: MockInstantDebouncer(queue: .main))
        var numberOfFailures = 0
        func fail() {
            empiricalConnectivity.connectionFail()
            numberOfFailures += 1
        }
        fail()
        _ = empiricalConnectivity.onEmpiricalConnectionAvailable
            .subscribe { available in
                if available {
                    XCTAssertEqual(empiricalConnectivity.numberOfFailedConsecutiveTimeouts, numberOfFailures)
                    connectionAvailable.fulfill()
                }
            }
        waitForExpectations(timeout: 1.0)
        empiricalConnectivity.connectionSuccess()
        XCTAssertEqual(empiricalConnectivity.numberOfFailedConsecutiveTimeouts, 0)
    }

    func test_increasing_numberOfFailedConsecutiveTimeouts_increases_the_connectivity_timeout() {
        let empiricalConnectivity = EmpiricalConnectivity(backoffPolocy: MockBackoff())
        let timeoutOnZeroFailures = empiricalConnectivity.timeoutInterval()
        empiricalConnectivity.numberOfFailedConsecutiveTimeouts = 5
        XCTAssertGreaterThan(empiricalConnectivity.timeoutInterval(), timeoutOnZeroFailures)
    }

    func test_connectivity_timeout_adds_1_to_numberOfFailedConsecutiveTimeouts() {
        let empiricalConnectivity = EmpiricalConnectivity(backoffPolocy: MockBackoff())
        XCTAssertEqual(empiricalConnectivity.timeoutInterval(), 1)
    }
}
