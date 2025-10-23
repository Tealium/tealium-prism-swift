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
    return TealiumNWPathMonitor(queue: TealiumQueue.worker)
    #else
    return AlwaysUnknownConnectivityMonitor()
    #endif
}
