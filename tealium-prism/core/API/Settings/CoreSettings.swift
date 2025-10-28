//
//  CoreConfig.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 06/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/// Describes all the available configurable settings that control behavior of core SDK functionality.
/// All settings available on this object are able to be set from remote, local and programmatic sources.
public struct CoreSettings: Equatable {
    static let id = "core"
    enum Keys {
        static let minLogLevel = "log_level"
        static let maxQueueSize = "max_queue_size"
        static let expirationSeconds = "expiration"
        static let refreshIntervalSeconds = "refresh_interval"
        static let visitorIdentityKey = "visitor_identity_key"
        static let sessionTimeout = "session_timeout"
    }
    enum Defaults {
        static let minLogLevel = LogLevel.Minimum.error
        static let maxQueueSize = 100
        static let queueExpiration = 1.days
        static let refreshInterval = 15.minutes
        static let sessionTimeout = 5.minutes
    }
    init(minLogLevel: LogLevel.Minimum? = nil,
         maxQueueSize: Int? = nil,
         queueExpiration: TimeFrame? = nil,
         refreshInterval: TimeFrame? = nil,
         visitorIdentityKey: String? = nil,
         sessionTimeout: TimeFrame? = nil) {
        self.minLogLevel = minLogLevel ?? Defaults.minLogLevel
        self.maxQueueSize = maxQueueSize ?? Defaults.maxQueueSize
        self.queueExpiration = queueExpiration ?? Defaults.queueExpiration
        self.refreshInterval = refreshInterval ?? Defaults.refreshInterval
        self.sessionTimeout = sessionTimeout ?? Defaults.sessionTimeout
        self.visitorIdentityKey = visitorIdentityKey
    }
    /// The minimum log level for messages.
    public let minLogLevel: LogLevel.Minimum
    /// How many events can be queued at any given time. Events will be removed
    /// on an oldest-first basis when the limit is reached.
    /// Negative value indicates an infinite queue length.
    public let maxQueueSize: Int
    /// How long events remain in the queue before expiring.
    /// If events cannot be processed by all registered `Dispatcher`s, then they will remain
    /// persisted until either this expiration time has elapsed, or they are eventually successfully processed
    /// by all registered `Dispatcher`s.
    public let queueExpiration: TimeFrame
    /// How often to refresh remote settings.
    public let refreshInterval: TimeFrame
    /// How long before a session times out.
    public let sessionTimeout: TimeFrame
    /// The key to look for in the data layer when identifying a user.
    /// This setting is used to automatically control when the Tealium Visitor Id is updated.
    public let visitorIdentityKey: String?
}
