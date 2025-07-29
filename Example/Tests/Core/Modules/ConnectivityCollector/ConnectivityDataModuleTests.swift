//
//  ConnectivityDataModuleTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 26/02/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ConnectivityDataModuleTests: XCTestCase {
    let monitor = MockConnectivityMonitor()
    lazy var connectivityCollector: ConnectivityDataModule! = ConnectivityDataModule(monitor: monitor)
    let dispatchContext = DispatchContext(source: .application, initialData: Dispatch(name: "connectivity").payload)

    // MARK: - Initialization Tests
    func test_initialization_is_successful_when_connectivity_collector_is_created() {
        XCTAssertNotNil(connectivityCollector, "ConnectivityDataModule should not be nil after initialization.")
        XCTAssertEqual(ConnectivityDataModule.id, "ConnectivityData", "ConnectivityDataModule id should be 'ConnectivityData'.")
        XCTAssertTrue(ConnectivityDataModule.canBeDisabled, "ConnectivityDataModule should be able to be disabled.")
    }

    // MARK: - Data Collection Tests
    func test_connection_type_collected_corresponds_to_monitor_connection() {
        let data = connectivityCollector.collect(dispatchContext)
        XCTAssertEqual(data.get(key: TealiumDataKey.connectionType), monitor.connection.value.toString())
    }
}
