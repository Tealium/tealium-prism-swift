//
//  MockConnectivity.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 14/06/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
@testable import tealium_swift

class MockConnectivityMonitor: ConnectivityMonitorProtocol {
    
    // MARK: ConnectivityMonitorProtocol
    
    @ToAnyObservable(TealiumReplaySubject<Connection>(initialValue: .unknown))
    public var onConnection: TealiumObservable<Connection>
    
    public var connection: Connection {
        $onConnection.last() ?? .unknown
    }
    
    // MARK: Testing Utilities
    
    func changeConnection(_ connection: Connection) {
        $onConnection.publishIfChanged(connection)
    }
    
    func reset() {
        $onConnection.clear()
        changeConnection(.unknown)
    }
}

class MockEmpiricalConnectivity: EmpiricalConnectivityProtocol {
    
    // MARK: EmpiricalConnectivityProtocol
    
    @ToAnyObservable(TealiumReplaySubject<Bool>(initialValue: true))
    var onEmpiricalConnectionAvailable: TealiumObservable<Bool>
    
    func connectionSuccess() {
        $onConnectionSuccess.publish()
    }
    
    func connectionFail() {
        $onConnectionFail.publish()
    }
    
    // MARK: Testing Utilities
    
    @ToAnyObservable(TealiumPublisher<Void>())
    var onConnectionSuccess: TealiumObservable<Void>
    
    @ToAnyObservable(TealiumPublisher<Void>())
    var onConnectionFail: TealiumObservable<Void>
    
    func changeConnectionAvailable(_ available: Bool) {
        $onEmpiricalConnectionAvailable.publishIfChanged(available)
    }
    
    func reset() {
        $onEmpiricalConnectionAvailable.clear()
        changeConnectionAvailable(true)
    }
}

class MockConnectivityManager: ConnectivityManager {
    init() {
        super.init(connectivityMonitor: MockConnectivityMonitor(),
                   empiricalConnectivity: MockEmpiricalConnectivity())
    }
}
