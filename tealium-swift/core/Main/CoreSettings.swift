//
//  CoreConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public struct CoreSettings {
    enum Keys {
        static let minLogLevel = "log_level"
        static let barriers = "barriers"
        static let transformations = "transformations"
        static let maxQueueSize = "max_queue_size"
        static let expirationSeconds = "expiration"
    }
    enum Defaults {
        static let minLogLevel = TealiumLogLevel.Minimum.debug // TODO: Change into .error later
        static let maxQueueSize = 100
        static let queueExpirationSeconds = 86_400
    }
    public init(coreDictionary: [String: Any]) {
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
        let expirationSeconds = coreDictionary[Keys.expirationSeconds] as? Int ?? Defaults.queueExpirationSeconds
        queueExpiration = TimeFrame(unit: .seconds, interval: expirationSeconds)
    }
    let minLogLevel: TealiumLogLevel.Minimum
    let scopedBarriers: [ScopedBarrier]
    let scopedTransformations: [ScopedTransformation]
    let maxQueueSize: Int
    let queueExpiration: TimeFrame
}
