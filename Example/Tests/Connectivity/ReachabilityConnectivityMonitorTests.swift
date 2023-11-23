//
//  ReachabilityConnectivityMonitorTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 14/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import SystemConfiguration
@testable import TealiumSwift
import XCTest

final class ReachabilityConnectivityMonitorTests: XCTestCase {

    let reachability = ReachabilityConnectivityMonitor(queue: .main)

    func test_reachability_can_be_initiated() {
        XCTAssertNotNil(reachability)
    }

    func test_reachability_monitor_can_be_deinitialized() {
        let reachabilityQueueCleared = expectation(description: "reachability queue should clear")
        let queue = DispatchQueue(label: "com.tealium.reachability-test")
        var monitor: ReachabilityConnectivityMonitor? = ReachabilityConnectivityMonitor(queue: queue)
        weak var weakMonitor = monitor

        monitor = nil
        queue.async { reachabilityQueueCleared.fulfill() }

        waitForExpectations(timeout: 1.0)
        XCTAssertNil(monitor, "strong reference should be nil")
        XCTAssertNil(weakMonitor, "weak reference should be nil")
    }

    func test_connection_starts_with_unknown() {
        let connectionChanged = expectation(description: "Connection change event should be reported")
        let reachability = ReachabilityConnectivityMonitor(queue: .main)
        XCTAssertEqual(reachability?.connection.value, .unknown)
        reachability?.$connection.subscribeOnce({ connection in
            XCTAssertEqual(connection, .unknown)
            connectionChanged.fulfill()
        })
        waitForExpectations(timeout: 2.0)
    }

    func test_connection_changes_after_init() {
        let connectionChanged = expectation(description: "Connection change event should be reported")
        let sub = reachability?.$connection.subscribe({ connection in
            if connection != .unknown {
                connectionChanged.fulfill()
            }
        })
        waitForExpectations(timeout: 2.0)
        sub?.dispose()
    }
}

final class TestConnectionFromFlags: XCTestCase {

    // MARK: - NetworkReachabilityStatus

    func test_connection_down_when_reachable_flag_is_absent() {
        let flags: SCNetworkReachabilityFlags = [.connectionOnDemand]

        let connection = NetworkConnection.fromFlags(flags)

        XCTAssertEqual(connection, .notConnected)
    }

    func test_connection_down_when_connection_is_required() {
        let flags: SCNetworkReachabilityFlags = [.reachable, .connectionRequired]

        let connection = NetworkConnection.fromFlags(flags)

        XCTAssertEqual(connection, .notConnected)
    }

    func test_conneciton_down_when_intervention_is_required() {
        let flags: SCNetworkReachabilityFlags = [.reachable, .connectionRequired, .interventionRequired]

        let connection = NetworkConnection.fromFlags(flags)

        XCTAssertEqual(connection, .notConnected)
    }

    func test_connection_is_wifi_as_default_when_reachable() {
        let flags: SCNetworkReachabilityFlags = [.reachable]

        let connection = NetworkConnection.fromFlags(flags)

        XCTAssertEqual(connection, .connected(.wifi))
    }

    func test_connection_is_wifi_as_default_when_connection_is_on_demand() {
        let flags: SCNetworkReachabilityFlags = [.reachable, .connectionRequired, .connectionOnDemand]

        let connection = NetworkConnection.fromFlags(flags)

        XCTAssertEqual(connection, .connected(.wifi))
    }

    func test_connection_is_wifi_as_default_when_connection_is_on_traffic() {
        let flags: SCNetworkReachabilityFlags = [.reachable, .connectionRequired, .connectionOnTraffic]

        let connection = NetworkConnection.fromFlags(flags)

        XCTAssertEqual(connection, .connected(.wifi))
    }

    #if os(iOS) || os(tvOS)
    func test_connection_is_cellular_when_is_WWAN() {
        let flags: SCNetworkReachabilityFlags = [.reachable, .isWWAN]

        let connection = NetworkConnection.fromFlags(flags)

        // Then
        XCTAssertEqual(connection, .connected(.cellular))
    }

    func test_connection_down_when_cellular_and_connection_is_required() {
        let flags: SCNetworkReachabilityFlags = [.reachable, .isWWAN, .connectionRequired]

        let connection = NetworkConnection.fromFlags(flags)

        XCTAssertEqual(connection, .notConnected)
    }
    #endif
}
