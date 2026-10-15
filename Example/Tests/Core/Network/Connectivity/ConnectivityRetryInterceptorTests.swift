//
//  ConnectivityRetryInterceptorTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConnectivityRetryInterceptorTests: XCTestCase {
    let connectionErrorResult = NetworkResult.failure(NetworkError(type: .urlError(URLError(.notConnectedToInternet))))
    let connectivityMonitor = MockConnectivityMonitor()
    let empiricalConnectivity = MockEmpiricalConnectivity()
    lazy var connectivityManager: ConnectivityManager = ConnectivityManager(queue: .main,
                                                                            connectivityMonitor: connectivityMonitor,
                                                                            empiricalConnectivity: empiricalConnectivity)
    lazy var interceptor = ConnectivityRetryInterceptor(connectivityManager: connectivityManager)

    func test_shouldRetry_returns_doNotRetry_on_connection_assumed_available() {
        XCTAssertTrue(connectivityManager.isConnectionAssumedAvailable)
        let policy = interceptor.shouldRetry(URLRequest(),
                                             consecutiveRetryCount: 0,
                                             with: connectionErrorResult)
        XCTAssertEqual(policy, .doNotRetry)
    }

    func test_shouldRetry_returns_doNotRetry_on_connection_assumed_unavailable_but_unretryable_error() {
        empiricalConnectivity.changeConnectionAvailable(false)
        connectivityMonitor.changeConnection(.notConnected)
        XCTAssertFalse(connectivityManager.isConnectionAssumedAvailable)
        let policy = interceptor.shouldRetry(URLRequest(),
                                             consecutiveRetryCount: 0,
                                             with: .failure(NetworkError(type: .unknown(nil))))
        XCTAssertEqual(policy, .doNotRetry)
    }

    func test_shouldRetry_returns_afterEvent_on_connection_assumed_unavailable() {
        empiricalConnectivity.changeConnectionAvailable(false)
        connectivityMonitor.changeConnection(.notConnected)
        XCTAssertFalse(connectivityManager.isConnectionAssumedAvailable)
        let policy = interceptor.shouldRetry(URLRequest(),
                                             consecutiveRetryCount: 0,
                                             with: connectionErrorResult)
        XCTAssertEqual(policy, .afterEvent(Observables.just(())))
    }
}
