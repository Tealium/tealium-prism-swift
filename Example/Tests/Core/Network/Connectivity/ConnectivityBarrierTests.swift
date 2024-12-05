//
//  ConnectivityBarrierTests.swift
//  tealium-swift_Tests
//
//  Created by Denis Guzov on 31/05/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConnectivityBarrierTests: XCTestCase {
    let manager = MockConnectivityManager()
    lazy var barrier = ConnectivityBarrier(onConnection: manager.connectionAssumedAvailable)

    func test_connectivity_barrier_is_open_when_connection_is_available() {
        let isInOpenState = expectation(description: "Barrier is in open state")
        barrier.onState.subscribeOnce { state in
            XCTAssertEqual(state, .open)
            isInOpenState.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_barrier_is_closed_when_connection_is_not_available() {
        let isInClosedState = expectation(description: "Barrier is in closed state")
        let empiricalConnectivity = manager.mockEmpiricalConnectivity
        empiricalConnectivity.changeConnectionAvailable(false)
        barrier.onState.subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            isInClosedState.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_barrier_updates_emitted_value_when_connectivity_status_is_updated() {
        let isInClosedState = expectation(description: "Barrier updated to .closed")
        let isInOpenState = expectation(description: "Barrier updated to .open")
        // check that initial value is as expected
        barrier.onState.subscribeOnce { state in
            XCTAssertEqual(state, .open)
        }
        let empiricalConnectivity = manager.mockEmpiricalConnectivity
        let disposable = barrier.onState.ignoreFirst().subscribe { state in
            switch state {
            case .closed:
                isInClosedState.fulfill()
            case .open:
                isInOpenState.fulfill()
            }
        }
        empiricalConnectivity.changeConnectionAvailable(false)
        empiricalConnectivity.changeConnectionAvailable(true)
        wait(for: [isInClosedState, isInOpenState], timeout: Self.defaultTimeout, enforceOrder: true)
        disposable.dispose()
    }
}
