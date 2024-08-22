//
//  CoreSettingsBuilder.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 23/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to enforce some of the `CoreSettings`.
public class CoreSettingsBuilder {
    typealias Keys = CoreSettings.Keys
    var minLogLevel: TealiumLogLevel.Minimum?
    var scopedBarriers: [ScopedBarrier]?
    var scopedTransformations: [ScopedTransformation]?
    var maxQueueSize: Int?
    var queueExpiration: TimeFrame?
    var refreshInterval: TimeFrame?

    /// Set the minimum level for logs to be logged by the entire library.
    public func setMinLogLevel(_ minLogLevel: TealiumLogLevel.Minimum) -> Self {
        self.minLogLevel = minLogLevel
        return self
    }

    /// Set the `ScopedBarrier`s that will be used to determine in what scope the relative `Barrier` will have to take place.
    public func setScopedBarriers(_ scopedBarriers: [ScopedBarrier]) -> Self {
        self.scopedBarriers = scopedBarriers
        return self
    }

    /// Set the `ScopedTransformation`s that will be used to determine in what scope the relative `Transformation` will have to take place.
    public func setScopedTransformations(_ scopedTransformations: [ScopedTransformation]) -> Self {
        self.scopedTransformations = scopedTransformations
        return self
    }

    /// Set the maximum number of `Dispatch`es that can be stored in the queue, in FIFO order: the first element added in the queue will be the first one to be deleted when the maximum is reached.
    public func setMaxQueueSize(_ maxQueueSize: Int) -> Self {
        self.maxQueueSize = maxQueueSize
        return self
    }

    /// Set the expiration for `Dispatch`es in the queue. If a `Dispatch` is not dequeued in the specified amount of time it will be deleted from the queue anyway.
    public func setQueueExpiration(_ queueExpiration: TimeFrame) -> Self {
        self.queueExpiration = queueExpiration
        return self
    }

    /// The minimum amount of time between remote settings refreshes. Refresh will happen anyway at every app startup, if a remote `settingsUrl` is provided in the `TealiumConfig`.
    public func setRefreshInterval(_ refreshInterval: TimeFrame) -> Self {
        self.refreshInterval = refreshInterval
        return self
    }

    func build() -> [String: Any]? {
        let logLevel: String? = minLogLevel?.toString()
        let scopedBarriers: [[String: Any]]? = scopedBarriers?.map { $0.toDictionary() }
        let scopedTransformations: [[String: Any]]? = scopedTransformations?.map { $0.toDictionary() }
        let expirationSeconds: Double? = queueExpiration?.seconds()
        let refreshIntervalSeconds: Double? = refreshInterval?.seconds()
        let dictionaryWithOptionals: [String: Any?] = [
            Keys.minLogLevel: logLevel,
            Keys.barriers: scopedBarriers,
            Keys.transformations: scopedTransformations,
            Keys.maxQueueSize: maxQueueSize,
            Keys.expirationSeconds: expirationSeconds,
            Keys.refreshIntervalSeconds: refreshIntervalSeconds
        ]
        return dictionaryWithOptionals.compactMapValues { $0 }
    }
}
