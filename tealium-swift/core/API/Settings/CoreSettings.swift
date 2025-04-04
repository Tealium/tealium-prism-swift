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
        static let barriers = "barriers"
        static let maxQueueSize = "max_queue_size"
        static let expirationSeconds = "expiration"
        static let refreshIntervalSeconds = "refresh_interval"
        static let visitorIdentityKey = "visitor_identity_key"
    }
    enum Defaults {
        static let minLogLevel = LogLevel.Minimum.error
        static let maxQueueSize = 100
        static let queueExpiration = TimeFrame(unit: .days, interval: 1)
        static let refreshInterval = TimeFrame(unit: .minutes, interval: 15)
    }
    init(minLogLevel: LogLevel.Minimum? = nil,
         scopedBarriers: [ScopedBarrier]? = nil,
         maxQueueSize: Int? = nil,
         queueExpiration: TimeFrame? = nil,
         refreshInterval: TimeFrame? = nil,
         visitorIdentityKey: String? = nil) {
        self.minLogLevel = minLogLevel ?? Defaults.minLogLevel
        self.scopedBarriers = scopedBarriers ?? []
        self.maxQueueSize = maxQueueSize ?? Defaults.maxQueueSize
        self.queueExpiration = queueExpiration ?? Defaults.queueExpiration
        self.refreshInterval = refreshInterval ?? Defaults.refreshInterval
        self.visitorIdentityKey = visitorIdentityKey
    }
    public let minLogLevel: LogLevel.Minimum
    public let scopedBarriers: [ScopedBarrier]
    public let maxQueueSize: Int
    public let queueExpiration: TimeFrame
    public let refreshInterval: TimeFrame
    public let visitorIdentityKey: String?
}
