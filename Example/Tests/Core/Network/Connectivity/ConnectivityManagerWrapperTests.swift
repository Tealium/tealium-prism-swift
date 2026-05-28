//
//  ConnectivityManagerWrapperTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 27/03/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConnectivityManagerWrapperTests: XCTestCase {

    let mockConnectivityManager = MockConnectivityManager(queue: .main)
    let queue = TealiumQueue(dispatchQueue: DispatchQueue(label: "Other Queue", target: .main))
    lazy var wrapper = mockConnectivityManager.publishingOn(queue: queue)

    func test_connection_updates_happen_on_the_provided_queue() {
        let connectionChanged = expectation(description: "Connection changed")
        _ = wrapper.connection
            .updates()
            .subscribe { connection in
                dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
                XCTAssertEqual(connection, .notConnected)
                connectionChanged.fulfill()
            }
        mockConnectivityManager.mockConnectivityMonitor.changeConnection(.notConnected)
        waitForLongTimeout()
    }

    func test_connectionAssumedAvailable_updates_happen_on_the_provided_queue() {
        let connectionAssumptionChanged = expectation(description: "Connection Assumption changed")
        _ = wrapper.connectionAssumedAvailable
            .updates()
            .subscribe { available in
                dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
                XCTAssertFalse(available)
                connectionAssumptionChanged.fulfill()
            }
        mockConnectivityManager.mockEmpiricalConnectivity.changeConnectionAvailable(false)
        waitForLongTimeout()
    }

    func test_connectionAssumption_default_is_the_same_as_the_wrapper_default() {
        let connectionAssumptionEmitted = expectation(description: "Connection Assumption emitted")
        let empiricalConnectivity = EmpiricalConnectivity(debouncer: MockDebouncer(queue: .main))
        empiricalConnectivity.onEmpiricalConnectionAvailable
            .subscribeOnce { available in
                XCTAssertEqual(self.wrapper.connectionAssumedAvailable.value, available)
                connectionAssumptionEmitted.fulfill()
            }
        waitForLongTimeout()
    }

    func test_connection_default_is_the_same_as_the_wrapper_default() {
        #if !os(watchOS)
        XCTAssertEqual(wrapper.connection.value, TealiumNWPathMonitor(queue: .main).connection.value)
        #else
        XCTAssertEqual(wrapper.connection.value, AlwaysUnknownConnectivityMonitor().connection.value)
        #endif
    }

}
