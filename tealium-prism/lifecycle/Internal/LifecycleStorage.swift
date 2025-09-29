//
//  LifecycleStorage.swift
//  tealium-prism
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumCore
#endif

class LifecycleStorage {
    let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    var currentAppVersion: String? {
        dataStore.get(key: LifecycleStorageKey.appVersion, as: String.self)
    }
    var priorSecondsAwake: Int64 {
        dataStore.get(key: LifecycleStorageKey.priorSecondsAwake, as: Int64.self) ?? 0
    }
    var timestampUpdate: Int64? {
        dataStore.get(key: LifecycleStorageKey.timestampUpdate, as: Int64.self)
    }
    var timestampFirstLaunch: Int64? {
        dataStore.get(key: LifecycleStorageKey.timestampFirstLaunch, as: Int64.self)
    }
    var timestampLastLaunch: Int64? {
        dataStore.get(key: LifecycleStorageKey.timestampLastLaunch, as: Int64.self)
    }
    var timestampLastSleep: Int64? {
        dataStore.get(key: LifecycleStorageKey.timestampLastSleep, as: Int64.self)
    }
    var timestampLastWake: Int64? {
        dataStore.get(key: LifecycleStorageKey.timestampLastWake, as: Int64.self)
    }
    var totalSecondsAwake: Int64 {
        dataStore.get(key: LifecycleStorageKey.totalSecondsAwake, as: Int64.self) ?? 0
    }
    var countLaunch: Int64 {
        dataStore.get(key: LifecycleStorageKey.countLaunch, as: Int64.self) ?? 0
    }
    var countSleep: Int64 {
        dataStore.get(key: LifecycleStorageKey.countSleep, as: Int64.self) ?? 0
    }
    var countWake: Int64 {
        dataStore.get(key: LifecycleStorageKey.countWake, as: Int64.self) ?? 0
    }
    var countTotalLaunch: Int64 {
        dataStore.get(key: LifecycleStorageKey.countTotalLaunch, as: Int64.self) ?? 0
    }
    var countTotalSleep: Int64 {
        dataStore.get(key: LifecycleStorageKey.countTotalSleep, as: Int64.self) ?? 0
    }
    var countTotalWake: Int64 {
        dataStore.get(key: LifecycleStorageKey.countTotalWake, as: Int64.self) ?? 0
    }
    var countTotalCrash: Int64 {
        dataStore.get(key: LifecycleStorageKey.countTotalCrash, as: Int64.self) ?? 0
    }

    var lastLifecycleEvent: LifecycleEvent? {
        guard let stringValue = dataStore.get(key: LifecycleStorageKey.lastEvent, as: String.self) else {
            return nil
        }
        return LifecycleEvent(rawValue: stringValue)
    }

    func registerLaunch(timestamp: Int64) throws {
        try dataStore.edit()
            .setLastWake(timestamp: timestamp)
            .setLastLifecycleEvent(event: .launch)
            .incrementLaunch(self)
            .incrementWake(self)
            .setLastLaunch(timestamp: timestamp)
            .commit()
    }

    func registerWake(timestamp: Int64) throws {
        try dataStore.edit()
            .setLastWake(timestamp: timestamp)
            .setLastLifecycleEvent(event: .wake)
            .incrementWake(self)
            .commit()
    }

    func registerSleep(timestamp: Int64, secondsAwake: Int64) throws {
        try dataStore.edit()
            .setLastLifecycleEvent(event: .sleep)
            .incrementSleep(self)
            .updateSecondsAwake(self, seconds: secondsAwake)
            .setLastSleep(timestamp: timestamp)
            .commit()
    }

    func setFirstLaunchTimestamp(timestamp: Int64) throws {
        if timestampFirstLaunch == nil {
            try dataStore.edit()
                .setFirstLaunchTimestamp(timestamp: timestamp)
                .commit()
        }
    }

    func setCurrentAppVersion(newVersion: String) throws {
        try dataStore.edit()
            .setCurrentAppVersion(version: newVersion)
            .commit()
    }

    func resetCountsAfterAppUpdate(timestamp: Int64, newVersion: String) throws {
        try dataStore.edit()
            .setCurrentAppVersion(version: newVersion)
            .setTimestampUpdate(timestamp: timestamp)
            .resetCounts()
            .commit()
    }

    func incrementCrash() throws {
        try dataStore.edit()
            .incrementCrash(self)
            .commit()
    }

    func resetPriorSecondsAwake() throws {
        try dataStore.edit()
            .resetPriorSecondsAwake()
            .commit()
    }
}
