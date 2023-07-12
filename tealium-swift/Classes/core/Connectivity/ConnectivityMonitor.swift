//
//  ConnectivityMonitor.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/05/23.
//

import Foundation

/// Just a Namespace for connectivity monitors
public class ConnectivityMonitor {
    public static let shared = defaultConnectivityMonitor()
}

private func defaultConnectivityMonitor() -> ConnectivityMonitorProtocol {
    #if !os(watchOS)
    if #available(iOS 12, tvOS 12, macCatalyst 13, OSX 10.14, *) {
        return TealiumNWPathMonitor()
    } else if let monitor = ReachabilityConnectivityMonitor() {
        return monitor
    }
    #endif
    return AlwaysUnknownConnectivityMonitor()
}
