//
//  NetworkConnection.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// The connection as it's reported by the system monitors
public enum NetworkConnection: Equatable {
    /// The type of connection that we have at the moment
    public enum ConnectionType {
        /// The connection is cellular or connected via hotspot to another phone
        case cellular
        /// The device is connected to the wifi network
        case wifi
        /// The device is wired via ethernet
        case ethernet
    }
    /// System reported that connection should be avilable and should use the given ConnectionType
    case connected(ConnectionType)
    /// System reported that connection should not be possible at the time
    case notConnected
    /// Always default until the monitored connectivity says otherwise
    case unknown

    var type: ConnectionType? {
        if case .connected(let type) = self {
            return type
        }
        return nil
    }
}
