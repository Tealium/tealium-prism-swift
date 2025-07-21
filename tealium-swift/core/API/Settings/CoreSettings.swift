//
//  CoreConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public struct CoreSettings: Equatable {
    static let id = "core"
    enum Keys {
        static let minLogLevel = "log_level"
        static let maxQueueSize = "max_queue_size"
        static let expirationSeconds = "expiration"
        static let refreshIntervalSeconds = "refresh_interval"
        static let visitorIdentityKey = "visitor_identity_key"
    }
    enum Defaults {
        static let minLogLevel = LogLevel.Minimum.error
        static let maxQueueSize = 100
        static let queueExpiration = 1.days
        static let refreshInterval = 15.minutes
    }
    init(minLogLevel: LogLevel.Minimum? = nil,
         maxQueueSize: Int? = nil,
         queueExpiration: TimeFrame? = nil,
         refreshInterval: TimeFrame? = nil,
         visitorIdentityKey: String? = nil) {
        self.minLogLevel = minLogLevel ?? Defaults.minLogLevel
        self.maxQueueSize = maxQueueSize ?? Defaults.maxQueueSize
        self.queueExpiration = queueExpiration ?? Defaults.queueExpiration
        self.refreshInterval = refreshInterval ?? Defaults.refreshInterval
        self.visitorIdentityKey = visitorIdentityKey
    }
    public let minLogLevel: LogLevel.Minimum
    public let maxQueueSize: Int
    public let queueExpiration: TimeFrame
    public let refreshInterval: TimeFrame
    public let visitorIdentityKey: String?
}
