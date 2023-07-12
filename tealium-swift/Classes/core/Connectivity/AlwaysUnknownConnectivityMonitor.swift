//
//  AlwaysUnknownConnectivityMonitor.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/05/23.
//

import Foundation

public struct AlwaysUnknownConnectivityMonitor: ConnectivityMonitorProtocol {
    public let onConnection: TealiumObservable<Connection> = TealiumObservable<Connection>.Just(.unknown)
    public let connection: Connection = .unknown
}
