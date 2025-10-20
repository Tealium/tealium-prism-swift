//
//  MockConnectivity.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 14/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

class MockConnectivityMonitor: ConnectivityMonitorProtocol {

    // MARK: ConnectivityMonitorProtocol

    @StateSubject(.unknown)
    var connection: ObservableState<NetworkConnection>

    // MARK: Testing Utilities

    func changeConnection(_ connection: NetworkConnection) {
        _connection.value = connection
    }

    func reset() {
        changeConnection(.unknown)
    }
}

class MockEmpiricalConnectivity: EmpiricalConnectivityProtocol {

    // MARK: EmpiricalConnectivityProtocol

    @ReplaySubject<Bool>(true)
    var onEmpiricalConnectionAvailable

    func connectionSuccess() {
        _onConnectionSuccess.publish()
    }

    func connectionFail() {
        _onConnectionFail.publish()
    }

    // MARK: Testing Utilities

    @Subject<Void> var onConnectionSuccess

    @Subject<Void> var onConnectionFail

    func changeConnectionAvailable(_ available: Bool) {
        _onEmpiricalConnectionAvailable.publishIfChanged(available)
    }

    func reset() {
        _onEmpiricalConnectionAvailable.clear()
        changeConnectionAvailable(true)
    }
}

class MockConnectivityManager: ConnectivityManager {
    let mockConnectivityMonitor: MockConnectivityMonitor
    let mockEmpiricalConnectivity: MockEmpiricalConnectivity
    init() {
        self.mockConnectivityMonitor = MockConnectivityMonitor()
        self.mockEmpiricalConnectivity = MockEmpiricalConnectivity()
        super.init(connectivityMonitor: mockConnectivityMonitor,
                   empiricalConnectivity: mockEmpiricalConnectivity)
    }
}
