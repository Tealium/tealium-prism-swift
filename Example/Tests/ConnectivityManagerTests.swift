//
//  ConnectivityManagerTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 14/06/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import tealium_swift

final class ConnectivityManagerTests: XCTestCase {
    let connectionErrorResult = NetworkResult.failure(.urlError(URLError(.notConnectedToInternet)))
    let connectivityMonitor = MockConnectivityMonitor()
    let empiricalConnectivity = MockEmpiricalConnectivity()
    var manager: ConnectivityManager!
    
    override func setUp() {
        manager = ConnectivityManager(connectivityMonitor: connectivityMonitor, empiricalConnectivity: empiricalConnectivity)
    }

    func test_connectivity_is_assumed_available_on_start() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.onConnectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func test_connectivity_is_still_assumed_available_after_empirical_connection_down() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.connected(.wifi))
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.onConnectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_connectivity_is_still_connected_after_connection_monitor_down() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.notConnected)
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.onConnectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func test_connectivity_is_unavailable_after_empirical_and_monitored_connection_down() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.notConnected)
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        manager.onConnectionAssumedAvailable.subscribeOnce { available in
            XCTAssertFalse(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func test_connectivity_returns_available_on_empirical_connection() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.notConnected)
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        empiricalConnectivity.changeConnectionAvailable(true)
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.onConnectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func test_connectivity_returns_available_on_monitored_connection() {
        let connectionAssumedAvailableEvent = expectation(description: "Event is returned")
        connectivityMonitor.changeConnection(.notConnected)
        empiricalConnectivity.changeConnectionAvailable(false)
        XCTAssertFalse(manager.isConnectionAssumedAvailable)
        connectivityMonitor.changeConnection(.connected(.wifi))
        XCTAssertTrue(manager.isConnectionAssumedAvailable)
        manager.onConnectionAssumedAvailable.subscribeOnce { available in
            XCTAssertTrue(available)
            connectionAssumedAvailableEvent.fulfill()
        }
        waitForExpectations(timeout: 1.0)
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
        waitForExpectations(timeout: 1.0)
    }
    
    func test_did_complete_with_success_causes_empirical_connection_success() {
        let empiricalConnectionSuccess = expectation(description: "Empirical connection success is reported")
        empiricalConnectivity.onConnectionSuccess.subscribeOnce {
            empiricalConnectionSuccess.fulfill()
        }
        manager.didComplete(URLRequest(), with: .success(.successful()))
        waitForExpectations(timeout: 1.0)
    }
    
    func test_did_complete_with_non200Status_error_causes_empirical_connection_success() {
        let empiricalConnectionSuccess = expectation(description: "Empirical connection success is reported")
        empiricalConnectivity.onConnectionSuccess.subscribeOnce {
            empiricalConnectionSuccess.fulfill()
        }
        manager.didComplete(URLRequest(), with: .failure(.non200Status(400)))
        waitForExpectations(timeout: 1.0)
    }
    
    func test_did_complete_with_non_connection_error_causes_nothing() {
        let empiricalConnectionSuccess = expectation(description: "Empirical connection success should not be reported")
        empiricalConnectionSuccess.isInverted = true
        let empiricalConnectionFailure = expectation(description: "Empirical connection failure should not be reported")
        empiricalConnectionFailure.isInverted = true
        let bag = TealiumDisposeBag()
        empiricalConnectivity.onConnectionSuccess.subscribe {
            empiricalConnectionSuccess.fulfill()
        }.toDisposeBag(bag)
        empiricalConnectivity.onConnectionFail.subscribe {
            empiricalConnectionFailure.fulfill()
        }.toDisposeBag(bag)
        manager.didComplete(URLRequest(), with: .failure(.urlError(URLError(.appTransportSecurityRequiresSecureConnection))))
        waitForExpectations(timeout: 1.0)
    }
    
    func test_waiting_for_connectivity_causes_empirical_connection_failure() {
        let empiricalConnectionFailure = expectation(description: "Empirical connection failure is reported")
        empiricalConnectivity.onConnectionFail.subscribeOnce {
            empiricalConnectionFailure.fulfill()
        }
        manager.waitingForConnectivity(URLSessionTask())
        waitForExpectations(timeout: 1.0)
    }
}


extension RetryPolicy: Equatable {
    /// Only for comparing during tests
    public static func == (lhs: tealium_swift.RetryPolicy, rhs: tealium_swift.RetryPolicy) -> Bool {
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
