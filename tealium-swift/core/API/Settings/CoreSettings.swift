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
        static let minLogLevel = LogLevel.Minimum.error
        static let maxQueueSize = 100
        static let queueExpiration = TimeFrame(unit: .days, interval: 1)
        static let refreshInterval = TimeFrame(unit: .minutes, interval: 15)
    }
    init(coreDataObject: DataObject) {
        minLogLevel = coreDataObject.get(key: Keys.minLogLevel)
            .flatMap { LogLevel.Minimum(from: $0) } ?? Defaults.minLogLevel
        scopedBarriers = coreDataObject.getDataArray(key: Keys.barriers)?
            .compactMap { $0.getConvertible(converter: ScopedBarrier.converter) } ?? []
        scopedTransformations = coreDataObject.getDataArray(key: Keys.transformations)?
            .compactMap { $0.getConvertible(converter: ScopedTransformation.converter) } ?? []
        maxQueueSize = coreDataObject.get(key: Keys.maxQueueSize) ?? Defaults.maxQueueSize
        queueExpiration = coreDataObject.getConvertible(key: Keys.expirationSeconds,
                                                        converter: TimeFrame.converter) ?? Defaults.queueExpiration
        refreshInterval = coreDataObject.getConvertible(key: Keys.refreshIntervalSeconds,
                                                        converter: TimeFrame.converter) ?? Defaults.refreshInterval
    }
    public let minLogLevel: LogLevel.Minimum
    public let scopedBarriers: [ScopedBarrier]
    public let scopedTransformations: [ScopedTransformation]
    public let maxQueueSize: Int
    public let queueExpiration: TimeFrame
    public let refreshInterval: TimeFrame
}
