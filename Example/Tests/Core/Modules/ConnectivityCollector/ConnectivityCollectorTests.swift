//
//  ConnectivityCollectorTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 26/02/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConnectivityCollectorTests: XCTestCase {
    let monitor = MockConnectivityMonitor()
    lazy var connectivityCollector: ConnectivityCollector! = ConnectivityCollector(monitor: monitor)
    let dispatchContext = DispatchContext(source: .application, initialData: Dispatch(name: "connectivity").payload)

    // MARK: - Initialization Tests
    func test_initialization_is_successful_when_connectivity_collector_is_created() {
        XCTAssertNotNil(connectivityCollector, "ConnectivityCollector should not be nil after initialization.")
        XCTAssertEqual(ConnectivityCollector.id, "Connectivity", "ConnectivityCollector id should be 'Connectivity'.")
        XCTAssertTrue(ConnectivityCollector.canBeDisabled, "ConnectivityCollector should be able to be disabled.")
    }

    // MARK: - Data Collection Tests
    func test_connection_type_collected_corresponds_to_monitor_connection() {
        let data = connectivityCollector.collect(dispatchContext)
        XCTAssertEqual(data.get(key: TealiumDataKey.connectionType), monitor.connection.value.toString())
    }
}
