//
//  EmpiricalConnectivityTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 13/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class EmpiricalConnectivityTests: XCTestCase {
    let debouncer = Debouncer(queue: TealiumQueue.worker)
    lazy var empiricalConnectivity = EmpiricalConnectivity(debouncer: debouncer)

    func test_connectivity_starts_with_assuming_available() {
        let connectionAvailable = expectation(description: "Empirical connection available")
        empiricalConnectivity.onEmpiricalConnectionAvailable
            .subscribeOnce { available in
                XCTAssertTrue(available)
                connectionAvailable.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_connectivity_becomes_unavailable_on_connection_failure() {
        let connectionNotAvailable = expectation(description: "Empirical connection is not available")
        empiricalConnectivity.connectionFail()
        empiricalConnectivity.onEmpiricalConnectionAvailable
            .subscribeOnce { available in
                XCTAssertFalse(available)
                connectionNotAvailable.fulfill()
            }
        waitForDefaultTimeout()
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
        waitForDefaultTimeout()
    }

    func test_connectivity_returns_available_on_timeout() {
        let connectionAvailableChange = expectation(description: "Connection is changed")
        connectionAvailableChange.expectedFulfillmentCount = 2
        let empiricalConnectivity = EmpiricalConnectivity(debouncer: MockDebouncer(queue: .main))
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
        waitForDefaultTimeout()
    }

    func test_connection_fail_without_success_increases_number_of_failures() {
        let connectionAvailable = expectation(description: "Connection returns Available")
        connectionAvailable.assertForOverFulfill = false
        connectionAvailable.expectedFulfillmentCount = 5
        let empiricalConnectivity = EmpiricalConnectivity(debouncer: MockDebouncer(queue: .main))
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
        waitForDefaultTimeout()
    }

    func test_connection_success_resets_number_of_failures() {
        let connectionAvailable = expectation(description: "Connection returns Available")
        let empiricalConnectivity = EmpiricalConnectivity(debouncer: MockDebouncer(queue: .main))
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
        waitForDefaultTimeout()
        empiricalConnectivity.connectionSuccess()
        XCTAssertEqual(empiricalConnectivity.numberOfFailedConsecutiveTimeouts, 0)
    }

    func test_increasing_numberOfFailedConsecutiveTimeouts_increases_the_connectivity_timeout() {
        let empiricalConnectivity = EmpiricalConnectivity(backoffPolicy: MockBackoff(), debouncer: debouncer)
        let timeoutOnZeroFailures = empiricalConnectivity.timeoutInterval()
        empiricalConnectivity.numberOfFailedConsecutiveTimeouts = 5
        XCTAssertGreaterThan(empiricalConnectivity.timeoutInterval(), timeoutOnZeroFailures)
    }

    func test_connectivity_timeout_adds_1_to_numberOfFailedConsecutiveTimeouts() {
        let empiricalConnectivity = EmpiricalConnectivity(backoffPolicy: MockBackoff(), debouncer: debouncer)
        XCTAssertEqual(empiricalConnectivity.timeoutInterval(), 1)
    }
}
