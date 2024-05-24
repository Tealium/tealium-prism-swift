//
//  ConnectivityProtocol.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol ConnectivityMonitorProtocol {
    var connection: TealiumStatefulObservable<NetworkConnection> { get }
}
