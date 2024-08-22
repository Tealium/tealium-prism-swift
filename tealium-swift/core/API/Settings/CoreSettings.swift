//
//  CoreConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public struct CoreSettings {
    static let id = "Core"
    enum Keys {
        static let minLogLevel = "log_level"
        static let barriers = "barriers"
        static let transformations = "transformations"
        static let maxQueueSize = "max_queue_size"
        static let expirationSeconds = "expiration"
        static let refreshIntervalSeconds = "refresh_interval"
    }
    enum Defaults {
        static let minLogLevel = TealiumLogLevel.Minimum.error
        static let maxQueueSize = 100
        static let queueExpirationSeconds: Double = 86_400
        static let refreshIntervalSeconds: Double = 900
    }
    init(coreDictionary: [String: Any]) {
        if let logLevelString = coreDictionary[Keys.minLogLevel] as? String,
           let level = TealiumLogLevel.Minimum(from: logLevelString) {
            minLogLevel = level
        } else {
            minLogLevel = Defaults.minLogLevel
        }
        if let barriers = coreDictionary[Keys.barriers] as? [[String: Any]] {
            scopedBarriers = barriers.compactMap { ScopedBarrier(from: $0) }
        } else {
            scopedBarriers = []
        }
        if let transformations = coreDictionary[Keys.transformations] as? [[String: Any]] {
            scopedTransformations = transformations.compactMap { ScopedTransformation(from: $0) }
        } else {
            scopedTransformations = []
        }
        maxQueueSize = coreDictionary[Keys.maxQueueSize] as? Int ?? Defaults.maxQueueSize
        queueExpiration = TimeFrame(unit: .seconds,
                                    interval: (coreDictionary[Keys.expirationSeconds] as? NSNumber)?.doubleValue ?? Defaults.queueExpirationSeconds)
        refreshInterval = TimeFrame(unit: .seconds,
                                    interval: (coreDictionary[Keys.refreshIntervalSeconds] as? NSNumber)?.doubleValue ?? Defaults.refreshIntervalSeconds)
    }
    public let minLogLevel: TealiumLogLevel.Minimum
    public let scopedBarriers: [ScopedBarrier]
    public let scopedTransformations: [ScopedTransformation]
    public let maxQueueSize: Int
    public let queueExpiration: TimeFrame
    public let refreshInterval: TimeFrame
}
