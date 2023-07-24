//
//  AlwaysUnknownConnectivityMonitor.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/05/23.
//

import Foundation

/**
 * For WatchOS we can't detect what type of connectivity we might have
 * as it returns notConnected also when there is connection available from a nearby phone
 */
public struct AlwaysUnknownConnectivityMonitor: ConnectivityMonitorProtocol {
    public let onConnection: TealiumObservable<NetworkConnection> = .Just(.unknown)
    public let connection: NetworkConnection = .unknown
}
