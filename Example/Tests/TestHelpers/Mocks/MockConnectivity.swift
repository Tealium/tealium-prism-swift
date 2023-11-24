//
//  MockConnectivity.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 14/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockConnectivityMonitor: ConnectivityMonitorProtocol {

    // MARK: ConnectivityMonitorProtocol

    @TealiumMutableState(.unknown)
    var connection: TealiumObservableState<NetworkConnection>

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

    @ToAnyObservable(TealiumReplaySubject<Bool>(initialValue: true))
    var onEmpiricalConnectionAvailable: TealiumObservable<Bool>

    func connectionSuccess() {
        _onConnectionSuccess.publish()
    }

    func connectionFail() {
        _onConnectionFail.publish()
    }

    // MARK: Testing Utilities

    @ToAnyObservable(TealiumPublisher<Void>())
    var onConnectionSuccess: TealiumObservable<Void>

    @ToAnyObservable(TealiumPublisher<Void>())
    var onConnectionFail: TealiumObservable<Void>

    func changeConnectionAvailable(_ available: Bool) {
        _onEmpiricalConnectionAvailable.publisher.publishIfChanged(available)
    }

    func reset() {
        _onEmpiricalConnectionAvailable.publisher.clear()
        changeConnectionAvailable(true)
    }
}

class MockConnectivityManager: ConnectivityManager {
    init() {
        super.init(connectivityMonitor: MockConnectivityMonitor(),
                   empiricalConnectivity: MockEmpiricalConnectivity())
    }
}
