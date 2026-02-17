//
//  ConnectivityBarrierTests.swift
//  tealium-prism_Tests
//
//  Created by Denis Guzov on 31/05/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConnectivityBarrierTests: XCTestCase {
    let manager = MockConnectivityManager()
    var configuration = DataObject()
    lazy var barrier = ConnectivityBarrier(connectionManager: manager, configuration: configuration)

    func test_connectivity_barrier_is_open_when_connection_is_available() {
        let isInOpenState = expectation(description: "Barrier is in open state")
        barrier.onState(for: "").subscribeOnce { state in
            XCTAssertEqual(state, .open)
            isInOpenState.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_barrier_is_closed_when_connection_is_not_available() {
        let isInClosedState = expectation(description: "Barrier is in closed state")
        let empiricalConnectivity = manager.mockEmpiricalConnectivity
        empiricalConnectivity.changeConnectionAvailable(false)
        barrier.onState(for: "").subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            isInClosedState.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_barrier_updates_emitted_value_when_connectivity_status_is_updated() {
        let isInClosedState = expectation(description: "Barrier updated to .closed")
        let isInOpenState = expectation(description: "Barrier updated to .open")
        // check that initial value is as expected
        barrier.onState(for: "").subscribeOnce { state in
            XCTAssertEqual(state, .open)
        }
        let empiricalConnectivity = manager.mockEmpiricalConnectivity
        let disposable = barrier.onState(for: "").ignoreFirst().subscribe { state in
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

    func test_connectivity_barrier_is_closed_when_connection_is_cellular_with_wifiOnly() {
        let isInClosedState = expectation(description: "Barrier is in closed state")
        configuration.set(true, key: ConnectivityBarrierConfiguration.Keys.wifiOnly)
        manager.mockConnectivityMonitor.changeConnection(.connected(.cellular))
        barrier.onState(for: "").subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            isInClosedState.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_barrier_closes_when_connection_becomes_cellular_with_wifiOnly() {
        let onStateChanged = expectation(description: "On State changed")
        onStateChanged.expectedFulfillmentCount = 2
        configuration.set(true, key: ConnectivityBarrierConfiguration.Keys.wifiOnly)
        barrier.onState(for: "").subscribeOnce { state in
            XCTAssertEqual(state, .open)
            onStateChanged.fulfill()
        }
        manager.mockConnectivityMonitor.changeConnection(.connected(.cellular))
        barrier.onState(for: "").subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            onStateChanged.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_connectivity_barrier_closes_when_connection_is_cellular_and_settings_update_to_wifiOnly() {
        let onStateChanged = expectation(description: "On State changed")
        onStateChanged.expectedFulfillmentCount = 2
        manager.mockConnectivityMonitor.changeConnection(.connected(.cellular))
        barrier.onState(for: "").subscribeOnce { state in
            XCTAssertEqual(state, .open)
            onStateChanged.fulfill()
        }
        configuration.set(true, key: ConnectivityBarrierConfiguration.Keys.wifiOnly)
        barrier.updateConfiguration(configuration)
        barrier.onState(for: "").subscribeOnce { state in
            XCTAssertEqual(state, .closed)
            onStateChanged.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_isFlushable_emits_false_when_connection_unknown() {
        let notFlushable = expectation(description: "isFlushable should emit false")
        barrier.isFlushable.subscribeOnce { isFlushable in
            XCTAssertFalse(isFlushable)
            notFlushable.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_isFlushable_emits_false_when_not_connected() {
        let notFlushable = expectation(description: "isFlushable should emit false")
        manager.mockConnectivityMonitor.changeConnection(.notConnected)
        barrier.isFlushable.subscribeOnce { isFlushable in
            XCTAssertFalse(isFlushable)
            notFlushable.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_isFlushable_emits_true_when_connected_to_wifi_network() {
        let flushable = expectation(description: "isFlushable should emit true")
        manager.mockConnectivityMonitor.changeConnection(.connected(.wifi))
        barrier.isFlushable.subscribeOnce { isFlushable in
            XCTAssertTrue(isFlushable)
            flushable.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_isFlushable_emits_true_when_connected_to_cellular_network() {
        let flushable = expectation(description: "isFlushable should emit true")
        manager.mockConnectivityMonitor.changeConnection(.connected(.cellular))
        barrier.isFlushable.subscribeOnce { isFlushable in
            XCTAssertTrue(isFlushable)
            flushable.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_isFlushable_emits_true_when_connected_through_ethernet() {
        let flushable = expectation(description: "isFlushable should emit true")
        manager.mockConnectivityMonitor.changeConnection(.connected(.ethernet))
        barrier.isFlushable.subscribeOnce { isFlushable in
            XCTAssertTrue(isFlushable)
            flushable.fulfill()
        }
        waitForDefaultTimeout()
    }
}

// MARK: - Factory Tests
extension ConnectivityBarrierTests {

    func test_factory_sets_default_scopes() {
        let factory = ConnectivityBarrier.Factory(defaultScopes: [.all])
        XCTAssertEqual(factory.defaultScopes(), [.all])
    }

    func test_factory_with_enforced_settings() {
        let enforcedSettings: DataObject = [
            ConnectivityBarrierConfiguration.Keys.wifiOnly: true
        ]
        let factory = ConnectivityBarrier.Factory(defaultScopes: [.all], enforcedSettings: enforcedSettings)

        XCTAssertEqual(factory.getEnforcedSettings(), enforcedSettings)
    }

    func test_factory_without_enforced_settings() {
        let factory = ConnectivityBarrier.Factory(defaultScopes: [.all])
        XCTAssertEqual(factory.getEnforcedSettings(), [:])
    }

    func test_factory_id_matches_barrier_id() {
        let factory = ConnectivityBarrier.Factory(defaultScopes: [])
        XCTAssertEqual(factory.id, ConnectivityBarrier.id)
    }
}
