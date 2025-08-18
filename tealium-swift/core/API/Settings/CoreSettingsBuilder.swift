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
    var dataObject = DataObject()

    /// Set the minimum level for logs to be logged by the entire library.
    public func setMinLogLevel(_ minLogLevel: LogLevel.Minimum) -> Self {
        dataObject.set(converting: minLogLevel, key: Keys.minLogLevel)
        return self
    }

    /// Set the maximum number of `Dispatch`es that can be stored in the queue, in FIFO order: the first element added in the queue will be the first one to be deleted when the maximum is reached.
    public func setMaxQueueSize(_ maxQueueSize: Int) -> Self {
        dataObject.set(maxQueueSize, key: Keys.maxQueueSize)
        return self
    }

    /// Set the expiration for `Dispatch`es in the queue. If a `Dispatch` is not dequeued in the specified amount of time it will be deleted from the queue anyway.
    public func setQueueExpiration(_ queueExpiration: TimeFrame) -> Self {
        dataObject.set(queueExpiration.inSeconds(), key: Keys.expirationSeconds)
        return self
    }

    /// The minimum amount of time between remote settings refreshes. Refresh will happen anyway at every app startup, if a remote `settingsUrl` is provided in the `TealiumConfig`.
    public func setRefreshInterval(_ refreshInterval: TimeFrame) -> Self {
        dataObject.set(refreshInterval.inSeconds(), key: Keys.refreshIntervalSeconds)
        return self
    }

    /// Sets the `visitorIdentityKey` to be looked at in the `DataLayer` to perform automatic visitor switching.
    public func setVisitorIdentityKey(_ visitorIdentityKey: String) -> Self {
        dataObject.set(visitorIdentityKey, key: Keys.visitorIdentityKey)
        return self
    }

    /// Sets the length of time of inactivity before a session should be considered expired, and a new one started.
    public func setSessionTimeout(_ sessionTimeout: TimeFrame) -> Self {
        dataObject.set(sessionTimeout.inSeconds(), key: Keys.sessionTimeout)
        return self
    }

    func build() -> DataObject {
        dataObject
    }
}
