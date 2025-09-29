//
//  ConnectivityMonitor.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Just a Namespace for connectivity monitors
public class ConnectivityMonitor {
    public static let shared = defaultConnectivityMonitor()
}

private func defaultConnectivityMonitor() -> ConnectivityMonitorProtocol {
    #if !os(watchOS)
    let queue = TealiumQueue.worker
    if #available(iOS 12, tvOS 12, macCatalyst 13, OSX 10.14, *) {
        return TealiumNWPathMonitor(queue: queue)
    } else if let monitor = ReachabilityConnectivityMonitor(queue: queue) {
        return monitor
    }
    #endif
    return AlwaysUnknownConnectivityMonitor()
}
