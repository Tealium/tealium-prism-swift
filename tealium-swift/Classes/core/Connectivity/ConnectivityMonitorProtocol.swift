//
//  ConnectivityProtocol.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/05/23.
//

import Foundation

public protocol ConnectivityMonitorProtocol {
    var onConnection: TealiumObservable<Connection> { get }
    var connection: Connection { get }
}
