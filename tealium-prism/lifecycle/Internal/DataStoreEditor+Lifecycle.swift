//
//  DataStoreEditor+Lifecycle.swift
//  tealium-prism
//
//  Created by Den Guzov on 28/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumPrismCore
#endif

// TODO: Perhaps, the best way to go would be to have an increment method in the DataStoreEditor, so that we can do the read and write in a transaction and don't need these dependencies to the Storage
extension DataStoreEditor {
    func incrementLaunch(_ storage: LifecycleStorage) -> Self {
        put(key: LifecycleStorageKey.countLaunch, value: storage.countLaunch + 1, expiry: Expiry.forever)
            .put(key: LifecycleStorageKey.countTotalLaunch, value: storage.countTotalLaunch + 1, expiry: Expiry.forever)
    }

    func incrementWake(_ storage: LifecycleStorage) -> Self {
        put(key: LifecycleStorageKey.countWake, value: storage.countWake + 1, expiry: Expiry.forever)
            .put(key: LifecycleStorageKey.countTotalWake, value: storage.countTotalWake + 1, expiry: Expiry.forever)
    }

    func incrementSleep(_ storage: LifecycleStorage) -> Self {
        put(key: LifecycleStorageKey.countSleep, value: storage.countSleep + 1, expiry: Expiry.forever)
            .put(key: LifecycleStorageKey.countTotalSleep, value: storage.countTotalSleep + 1, expiry: Expiry.forever)
    }

    func incrementCrash(_ storage: LifecycleStorage) -> Self {
        put(key: LifecycleStorageKey.countTotalCrash, value: storage.countTotalCrash + 1, expiry: Expiry.forever)
    }

    func setFirstLaunchTimestamp(timestamp: Int64) -> Self {
        put(key: LifecycleStorageKey.timestampFirstLaunch, value: timestamp, expiry: Expiry.forever)
    }

    func setLastLaunch(timestamp: Int64) -> Self {
        put(key: LifecycleStorageKey.timestampLastLaunch, value: timestamp, expiry: Expiry.forever)
    }

    func setLastSleep(timestamp: Int64) -> Self {
        put(key: LifecycleStorageKey.timestampLastSleep, value: timestamp, expiry: Expiry.forever)
    }

    func setLastWake(timestamp: Int64) -> Self {
        put(key: LifecycleStorageKey.timestampLastWake, value: timestamp, expiry: Expiry.forever)
    }

    func setLastLifecycleEvent(event: LifecycleEvent) -> Self {
        put(key: LifecycleStorageKey.lastEvent, value: event.toDataInput(), expiry: Expiry.forever)
    }

    func updateSecondsAwake(_ storage: LifecycleStorage, seconds: Int64) -> Self {
        put(key: LifecycleStorageKey.totalSecondsAwake, value: storage.totalSecondsAwake + seconds, expiry: Expiry.forever)
            .put(key: LifecycleStorageKey.priorSecondsAwake, value: storage.priorSecondsAwake + seconds, expiry: Expiry.forever)
    }

    func resetPriorSecondsAwake() -> Self {
        remove(key: LifecycleStorageKey.priorSecondsAwake)
    }

    func setCurrentAppVersion(version: String) -> Self {
        put(key: LifecycleStorageKey.appVersion, value: version, expiry: Expiry.forever)
    }

    func setTimestampUpdate(timestamp: Int64) -> Self {
        put(key: LifecycleStorageKey.timestampUpdate, value: timestamp, expiry: Expiry.forever)
    }

    func resetCounts() -> Self {
        remove(key: LifecycleStorageKey.countLaunch)
            .remove(key: LifecycleStorageKey.countWake)
            .remove(key: LifecycleStorageKey.countSleep)
    }
}
