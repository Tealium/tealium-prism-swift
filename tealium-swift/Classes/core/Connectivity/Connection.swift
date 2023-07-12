//
//  Connection.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/05/23.
//

import Foundation

public enum Connection: Equatable {
    public enum ConnectionType {
        case cellular
        case wifi
        case ethernet
    }
    case connected(ConnectionType)
    case notConnected
    case unknown
    
    var type: ConnectionType? {
        if case .connected(let type) = self {
            return type
        }
        return nil
    }
}
