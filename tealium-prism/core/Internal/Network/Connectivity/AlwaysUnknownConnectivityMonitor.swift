//
//  AlwaysUnknownConnectivityMonitor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * For WatchOS we can't detect what type of connectivity we might have
 * as it returns notConnected also when there is connection available from a nearby phone
 */
public struct AlwaysUnknownConnectivityMonitor: ConnectivityMonitorProtocol {
    public var connection: ObservableState<NetworkConnection> = .constant(.unknown)
}
