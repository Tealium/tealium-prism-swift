//
//  ConnectivityManagerTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 14/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConnectivityManagerTests: XCTestCase {
    let connectionErrorResult = NetworkResult.failure(NetworkError(type: .urlError(URLError(.notConnectedToInternet))))
    let connectivityMonitor = MockConnectivityMonitor()
    let empiricalConnectivity = MockEmpiricalConnectivity()
    lazy var manager: ConnectivityManager = ConnectivityManager(queue: .main,
                                                                connectivityMonitor: connectivityMonitor,
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

    func test_connectivity_is_unavailable_after_connection_monitor_down_even_if_empirical_is_available() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        empiricalConnectivity.changeConnectionAvailable(true)
        connectivityMonitor.changeConnection(.notConnected)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        manager.connectionAssumedAvailable.subscribeOnce { available in
            XCTAssertFalse(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_follows_empirical_when_monitor_goes_back_to_unknown() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.notConnected)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        empiricalConnectivity.changeConnectionAvailable(true)
        connectivityMonitor.changeConnection(.unknown)
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        manager.connectionAssumedAvailable.subscribeOnce { available in
            XCTAssertFalse(available)
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

    func test_onAttemptResult_with_connection_error_causes_empirical_connection_failure() {
        let empiricalConnectionFailure = expectation(description: "Empirical connection failure is reported")
        empiricalConnectivity.onConnectionFail.subscribeOnce {
            empiricalConnectionFailure.fulfill()
        }
        manager.onAttemptResult(URLRequest(), retryCount: 0, with: connectionErrorResult)
        waitForDefaultTimeout()
    }

    func test_onAttemptResult_with_success_causes_empirical_connection_success() {
        let empiricalConnectionSuccess = expectation(description: "Empirical connection success is reported")
        empiricalConnectivity.onConnectionSuccess.subscribeOnce {
            empiricalConnectionSuccess.fulfill()
        }
        manager.onAttemptResult(URLRequest(), retryCount: 0, with: .success(.successful()))
        waitForDefaultTimeout()
    }

    func test_onAttemptResult_with_urlResponse_error_causes_empirical_connection_success() {
        let empiricalConnectionSuccess = expectation(description: "Empirical connection success is reported")
        empiricalConnectivity.onConnectionSuccess.subscribeOnce {
            empiricalConnectionSuccess.fulfill()
        }
        manager.onAttemptResult(URLRequest(), retryCount: 0, with: .failure(NetworkError(type: .non200Status(400, nil),
                                                                                         urlResponse: .successful())))
        waitForDefaultTimeout()
    }

    func test_onAttemptResult_with_non_connection_error_causes_nothing() {
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
        manager.onAttemptResult(URLRequest(),
                                retryCount: 0,
                                with: .failure(NetworkError(type: .urlError(URLError(.appTransportSecurityRequiresSecureConnection)))))
        waitForDefaultTimeout()
    }

}
