//
//  ConnectivityManagerTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 14/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConnectivityManagerTests: XCTestCase {
    let connectionErrorResult = NetworkResult.failure(.urlError(URLError(.notConnectedToInternet)))
    let connectivityMonitor = MockConnectivityMonitor()
    let empiricalConnectivity = MockEmpiricalConnectivity()
    lazy var manager: ConnectivityManager = ConnectivityManager(connectivityMonitor: connectivityMonitor,
                                                                empiricalConnectivity: empiricalConnectivity)

    func test_connectivity_is_assumed_available_on_start() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.connectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_is_still_assumed_available_after_empirical_connection_down() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.connected(.wifi))
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.connectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_is_still_connected_after_connection_monitor_down() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.notConnected)
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.connectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_is_unavailable_after_empirical_and_monitored_connection_down() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.notConnected)
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        manager.connectionAssumedAvailable.subscribeOnce { available in
            XCTAssertFalse(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_does_not_return_available_on_empirical_connection_returning_available() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.notConnected)
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        empiricalConnectivity.changeConnectionAvailable(true)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        manager.connectionAssumedAvailable.subscribeOnce { available in
            XCTAssertFalse(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_returns_available_on_empirical_connection_returning_available_when_connection_unknown() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.unknown)
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        empiricalConnectivity.changeConnectionAvailable(true)
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.connectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_returns_available_on_monitored_connection() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.notConnected)
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        connectivityMonitor.changeConnection(.connected(.wifi))
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.connectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_should_retry_returns_doNotRetry_on_connection_assumed_available() {
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        let policy = manager.shouldRetry(URLRequest(),
                                         retryCount: 0,
                                         with: connectionErrorResult)
        XCTAssertEqual(policy, .doNotRetry)
    }

    func test_should_retry_returns_doNotRetry_on_connection_assumed_available_but_unretyable_error() {
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        empiricalConnectivity.changeConnectionAvailable(false)
        connectivityMonitor.changeConnection(.notConnected)
        let policy = manager.shouldRetry(URLRequest(),
                                         retryCount: 0,
                                         with: .failure(.unknown(nil)))
        XCTAssertEqual(policy, .doNotRetry)
    }

    func test_should_retry_returns_afterEvent_on_connection_assumed_unavailable() {
        empiricalConnectivity.changeConnectionAvailable(false)
        connectivityMonitor.changeConnection(.notConnected)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        let policy = manager.shouldRetry(URLRequest(),
                                         retryCount: 0,
                                         with: connectionErrorResult)
        XCTAssertEqual(policy, .afterEvent(.Just(())))
    }

    func test_did_complete_with_connection_error_causes_empirical_connection_failure() {
        let empiricalConnectionFailure = expectation(description: "Empirical connection failure is reported")
        empiricalConnectivity.onConnectionFail.subscribeOnce {
            empiricalConnectionFailure.fulfill()
        }
        manager.didComplete(URLRequest(), with: connectionErrorResult)
        waitForDefaultTimeout()
    }

    func test_did_complete_with_success_causes_empirical_connection_success() {
        let empiricalConnectionSuccess = expectation(description: "Empirical connection success is reported")
        empiricalConnectivity.onConnectionSuccess.subscribeOnce {
            empiricalConnectionSuccess.fulfill()
        }
        manager.didComplete(URLRequest(), with: .success(.successful()))
        waitForDefaultTimeout()
    }

    func test_did_complete_with_non200Status_error_causes_empirical_connection_success() {
        let empiricalConnectionSuccess = expectation(description: "Empirical connection success is reported")
        empiricalConnectivity.onConnectionSuccess.subscribeOnce {
            empiricalConnectionSuccess.fulfill()
        }
        manager.didComplete(URLRequest(), with: .failure(.non200Status(400)))
        waitForDefaultTimeout()
    }

    func test_did_complete_with_non_connection_error_causes_nothing() {
        let empiricalConnectionSuccess = expectation(description: "Empirical connection success should not be reported")
        empiricalConnectionSuccess.isInverted = true
        let empiricalConnectionFailure = expectation(description: "Empirical connection failure should not be reported")
        empiricalConnectionFailure.isInverted = true
        let automaticDisposer = AutomaticDisposer()
        empiricalConnectivity.onConnectionSuccess.subscribe {
            empiricalConnectionSuccess.fulfill()
        }.addTo(automaticDisposer)
        empiricalConnectivity.onConnectionFail.subscribe {
            empiricalConnectionFailure.fulfill()
        }.addTo(automaticDisposer)
        manager.didComplete(URLRequest(), with: .failure(.urlError(URLError(.appTransportSecurityRequiresSecureConnection))))
        waitForDefaultTimeout()
    }

    @available(tvOS, deprecated: 13.0, message: "URLSessionTask init not supported")
    @available(macOS, deprecated: 10.15, message: "URLSessionTask init not supported")
    func test_waiting_for_connectivity_causes_empirical_connection_failure() {
        let empiricalConnectionFailure = expectation(description: "Empirical connection failure is reported")
        empiricalConnectivity.onConnectionFail.subscribeOnce {
            empiricalConnectionFailure.fulfill()
        }
        manager.waitingForConnectivity(URLSessionTask())
        waitForDefaultTimeout()
    }
}

extension TealiumSwift.RetryPolicy: Swift.Equatable {
    /// Only for comparing during tests
    public static func == (lhs: RetryPolicy, rhs: RetryPolicy) -> Bool {
        switch (lhs, rhs) {
        case (.doNotRetry, .doNotRetry),
            (.afterEvent, .afterEvent),
            (.afterDelay, .afterDelay):
            return true
        default:
            return false
        }
    }
}
