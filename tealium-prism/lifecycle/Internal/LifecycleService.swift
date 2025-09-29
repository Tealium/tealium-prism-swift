//
//  LifecycleService.swift
//  tealium-prism
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
#if lifecycle
import TealiumCore
#endif

/**
 * The `LifecycleService` manages lifecycle events and provides methods for registering
 * launch, wake, and sleep events, as well as retrieving the current lifecycle state.
 */
class LifecycleService {
    private let lifecycleStorage: LifecycleStorage
    let calendar: Calendar = Calendar.current

    var updateLaunchDate: String?
    var firstLaunchString: String?
    var firstLaunchMmDdYyyy: String?
    var lastLaunchString: String?
    var lastSleepString: String?
    var lastWakeString: String?

    var lastLifecycleEvent: LifecycleEvent? {
        lifecycleStorage.lastLifecycleEvent
    }

    let bundle: Bundle

    init(lifecycleStorage: LifecycleStorage, bundle: Bundle) {
        self.lifecycleStorage = lifecycleStorage
        self.bundle = bundle
    }

    /**
     * Registers a launch event.
     *
     * - Parameters:
     *   - timestamp: The timestamp of the `launch` event.
     * - Returns: A `DataObject` containing information of the launch event.
     */
    func registerLaunch(timestamp: Int64) throws -> DataObject {
        let isFirstLaunchAfterInstall = lifecycleStorage.timestampFirstLaunch == nil
        if isFirstLaunchAfterInstall {
            try lifecycleStorage.setFirstLaunchTimestamp(timestamp: timestamp)
        }

        let currentVersion = bundle.version ?? ""
        let didUpdate = try updateAppVersion(timestamp: timestamp, initializedCurrentVersion: currentVersion)

        let lastWake = lifecycleStorage.timestampLastWake
        var state: DataObject = try getStateWithFirstWake(lastWake: lastWake, timestamp: timestamp)
        if didDetectCrash() {
            state.set(true, key: LifecycleStateKey.didDetectCrash)
            try lifecycleStorage.incrementCrash()
        }
        // we should cache the following values before timestamps are updated inside registerLaunch ...
        let daysSinceLastWake = daysSince(startEventMs: lifecycleStorage.timestampLastWake, endEventMs: timestamp)
        let prevLaunchString = lastLaunchString ?? setFormattedLastLaunch()
        let prevWakeString = lastWakeString ?? setFormattedLastWake()

        try lifecycleStorage.registerLaunch(timestamp: timestamp)
        lastLaunchString = Date(unixMilliseconds: timestamp).iso8601String
        lastWakeString = lastLaunchString

        state.set(converting: LifecycleEvent.launch, key: LifecycleStateKey.type)
        state.set(lifecycleStorage.priorSecondsAwake, key: LifecycleStateKey.priorSecondsAwake)
        try lifecycleStorage.resetPriorSecondsAwake()

        if isFirstLaunchAfterInstall {
            state.set(true, key: LifecycleStateKey.isFirstLaunch)
        }

        if didUpdate {
            state.set(true, key: LifecycleStateKey.isFirstLaunchUpdate)
        }

        state += getCurrentState(timestamp: timestamp, lifecycleEvent: .launch)
        // ... and override corresponding state values afterwards
        if let daysSinceLastWake {
            state.set(daysSinceLastWake, key: LifecycleStateKey.daysSinceLastWake)
        } else {
            state.removeValue(forKey: LifecycleStateKey.daysSinceLastWake)
        }
        if let prevLaunchString {
            state.set(prevLaunchString, key: LifecycleStateKey.lastLaunchDate)
        } else {
            state.removeValue(forKey: LifecycleStateKey.lastLaunchDate)
        }
        if let prevWakeString {
            state.set(prevWakeString, key: LifecycleStateKey.lastWakeDate)
        } else {
            state.removeValue(forKey: LifecycleStateKey.lastWakeDate)
        }
        return state
    }

    /**
     * Registers a wake event.
     *
     * - Parameters:
     *   - timestamp: The timestamp of the `wake` event.
     * - Returns: A `DataObject` containing information of the wake event.
     */
    func registerWake(timestamp: Int64) throws -> DataObject {
        let lastWake = lifecycleStorage.timestampLastWake
        var state = try getStateWithFirstWake(lastWake: lastWake, timestamp: timestamp)
        // we should cache the following values before timestamps are updated inside registerWake ...
        let daysSinceLastWake = daysSince(startEventMs: lifecycleStorage.timestampLastWake, endEventMs: timestamp)
        let prevWakeString = lastWakeString ?? setFormattedLastWake()

        try lifecycleStorage.registerWake(timestamp: timestamp)
        lastWakeString = Date(unixMilliseconds: timestamp).iso8601String

        state.set(converting: LifecycleEvent.wake, key: LifecycleStateKey.type)
        state += getCurrentState(timestamp: timestamp, lifecycleEvent: .wake)
        // ... and override corresponding state values afterwards
        if let daysSinceLastWake {
            state.set(daysSinceLastWake, key: LifecycleStateKey.daysSinceLastWake)
        } else {
            state.removeValue(forKey: LifecycleStateKey.daysSinceLastWake)
        }
        if let prevWakeString {
            state.set(prevWakeString, key: LifecycleStateKey.lastWakeDate)
        } else {
            state.removeValue(forKey: LifecycleStateKey.lastWakeDate)
        }
        return state
    }

    /**
     * Registers a sleep event.
     * - Parameters:
     *    - timestamp: The timestamp of the `sleep` event.
     * - Returns: A `DataObject` containing information of the sleep event.
     */
    func registerSleep(timestamp: Int64) throws -> DataObject {
        let foregroundStart: Int64 = lifecycleStorage.timestampLastWake ?? timestamp
        let secondsAwakeDelta: Int64 = (timestamp - foregroundStart) / 1000
        // we should cache the following value before timestamp is updated inside registerSleep ...
        let prevSleepString = lastSleepString ?? setFormattedLastSleep()

        try lifecycleStorage.registerSleep(timestamp: timestamp, secondsAwake: secondsAwakeDelta)
        lastSleepString = Date(unixMilliseconds: timestamp).iso8601String

        var state: DataObject = [:]
        state.set(converting: LifecycleEvent.sleep, key: LifecycleStateKey.type)
        state += getCurrentState(timestamp: timestamp, lifecycleEvent: .sleep)
        // ... and override corresponding state value afterwards
        if let prevSleepString {
            state.set(prevSleepString, key: LifecycleStateKey.lastSleepDate)
        } else {
            state.removeValue(forKey: LifecycleStateKey.lastSleepDate)
        }
        return state
    }

    /**
     * Retrieves current lifecycle state.
     * - Parameters:
     *   - timestamp: The current timestamp.
     *   - lifecycleEvent: The `LifecycleEvent` if it's registered by lifecycle module.
     * - Returns: A `DataObject` containing information of the current lifecycle state.
     */
    func getCurrentState(timestamp: Int64, lifecycleEvent: LifecycleEvent? = nil) -> DataObject {
        var state: DataObject = [:]
        let date = Date(unixMilliseconds: timestamp)
        state.set(getDayOfWeekLocal(currentDate: date), key: LifecycleStateKey.dayOfWeekLocal)
        state.set(getHourOfDayLocal(currentDate: date), key: LifecycleStateKey.hourOfDayLocal)
        updateDaysSince(timestamp: timestamp, state: &state)
        state.set(lifecycleStorage.countLaunch, key: LifecycleStateKey.launchCount)
        state.set(lifecycleStorage.countSleep, key: LifecycleStateKey.sleepCount)
        state.set(lifecycleStorage.countWake, key: LifecycleStateKey.wakeCount)
        state.set(lifecycleStorage.countTotalCrash, key: LifecycleStateKey.totalCrashCount)
        state.set(lifecycleStorage.countTotalLaunch, key: LifecycleStateKey.totalLaunchCount)
        state.set(lifecycleStorage.countTotalSleep, key: LifecycleStateKey.totalSleepCount)
        state.set(lifecycleStorage.countTotalWake, key: LifecycleStateKey.totalWakeCount)

        var secondsAwakeDelta: Int64 = 0
        if lifecycleEvent != .launch {
            var currentSecondsAwake = lifecycleStorage.priorSecondsAwake
            if lifecycleEvent == nil && lastLifecycleEvent != .sleep {
                secondsAwakeDelta = (timestamp - (lifecycleStorage.timestampLastWake ?? timestamp)) / 1000
                currentSecondsAwake += secondsAwakeDelta
            }
            state.set(currentSecondsAwake, key: LifecycleStateKey.secondsAwake)
        }
        state.set(lifecycleStorage.totalSecondsAwake + secondsAwakeDelta, key: LifecycleStateKey.totalSecondsAwake)

        if let firstLaunchString = firstLaunchString ?? setFormattedFirstLaunch(fallbackTimestamp: timestamp) {
            state.set(firstLaunchString, key: LifecycleStateKey.firstLaunchDate)
        }

        if let firstLaunchMmDdYyyy = firstLaunchMmDdYyyy ?? setFirstLaunchMmDdYyyy(fallbackTimestamp: timestamp) {
            state.set(firstLaunchMmDdYyyy, key: LifecycleStateKey.firstLaunchDateMmddyyyy)
        }

        if let lastLaunchString = lastLaunchString ?? setFormattedLastLaunch() {
            state.set(lastLaunchString, key: LifecycleStateKey.lastLaunchDate)
        }

        if let lastWakeString = lastWakeString ?? setFormattedLastWake() {
            state.set(lastWakeString, key: LifecycleStateKey.lastWakeDate)
        }

        if let lastSleepString = lastSleepString ?? setFormattedLastSleep() {
            state.set(lastSleepString, key: LifecycleStateKey.lastSleepDate)
        }

        if lifecycleStorage.timestampUpdate != nil {
            if let updateLaunchDate = updateLaunchDate ?? setUpdateLaunchDate() {
                state.set(updateLaunchDate, key: LifecycleStateKey.updateLaunchDate)
            }
        }
        return state
    }

    private func updateDaysSince(timestamp: Int64, state: inout DataObject) {
        if let daysSinceFirstLaunch = daysSince(startEventMs: lifecycleStorage.timestampFirstLaunch, endEventMs: timestamp) {
            state.set(daysSinceFirstLaunch, key: LifecycleStateKey.daysSinceFirstLaunch)
        }
        if let daysSinceLastWake = daysSince(startEventMs: lifecycleStorage.timestampLastWake, endEventMs: timestamp) {
            state.set(daysSinceLastWake, key: LifecycleStateKey.daysSinceLastWake)
        }
        if let daysSinceUpdate = daysSince(startEventMs: lifecycleStorage.timestampUpdate, endEventMs: timestamp) {
            state.set(daysSinceUpdate, key: LifecycleStateKey.daysSinceUpdate)
        }
    }

    private func getStateWithFirstWake(
        lastWake: Int64?,
        timestamp: Int64
    ) throws -> DataObject {
        var state: DataObject = [:]
        guard let lastWake else {
            state.set(true, key: LifecycleStateKey.isFirstWakeMonth)
            state.set(true, key: LifecycleStateKey.isFirstWakeToday)
            return state
        }
        let firstWakeResult = FirstWakeType(prevTimestampMs: lastWake, curTimestampMs: timestamp, calendar: calendar) ?? .neither
        if firstWakeResult.isFirstWakeMonth {
            state.set(true, key: LifecycleStateKey.isFirstWakeMonth)
            state.set(true, key: LifecycleStateKey.isFirstWakeToday)
        } else if firstWakeResult.isFirstWakeToday {
            state.set(true, key: LifecycleStateKey.isFirstWakeToday)
        }
        return state
    }

    func setFormattedFirstLaunch(fallbackTimestamp: Int64 = Date().unixTimeMilliseconds) -> String? {
        firstLaunchString = Date(unixMilliseconds: lifecycleStorage.timestampFirstLaunch ?? fallbackTimestamp).iso8601String
        return firstLaunchString
    }

    func setFirstLaunchMmDdYyyy(fallbackTimestamp: Int64 = Date().unixTimeMilliseconds) -> String? {
        firstLaunchMmDdYyyy = Date(unixMilliseconds: lifecycleStorage.timestampFirstLaunch ?? fallbackTimestamp).mmDDYYYYString
        return firstLaunchMmDdYyyy
    }

    func setFormattedLastLaunch() -> String? {
        guard let timestamp = lifecycleStorage.timestampLastLaunch else {
            lastLaunchString = nil
            return nil
        }
        lastLaunchString = Date(unixMilliseconds: timestamp).iso8601String
        return lastLaunchString
    }

    func setFormattedLastWake() -> String? {
        guard let timestamp = lifecycleStorage.timestampLastWake else {
            lastWakeString = nil
            return nil
        }
        lastWakeString = Date(unixMilliseconds: timestamp).iso8601String
        return lastWakeString
    }

    func setFormattedLastSleep() -> String? {
        guard let timestamp = lifecycleStorage.timestampLastSleep else {
            lastSleepString = nil
            return nil
        }
        lastSleepString = Date(unixMilliseconds: timestamp).iso8601String
        return lastSleepString
    }

    func setUpdateLaunchDate() -> String? {
        guard let timestampUpdate = lifecycleStorage.timestampUpdate else {
            updateLaunchDate = nil
            return nil
        }
        updateLaunchDate = Date(unixMilliseconds: timestampUpdate).iso8601String
        return updateLaunchDate
    }

    func didDetectCrash() -> Bool {
        guard let lastLifecycleEvent else {
            return false
        }
        return [LifecycleEvent.launch, LifecycleEvent.wake].contains(lastLifecycleEvent)
    }

    func updateAppVersion(timestamp: Int64, initializedCurrentVersion: String) throws -> Bool {
        let cachedVersion = lifecycleStorage.currentAppVersion

        if cachedVersion == nil {
            try lifecycleStorage.setCurrentAppVersion(newVersion: initializedCurrentVersion)
        } else if initializedCurrentVersion != cachedVersion {
            try lifecycleStorage.resetCountsAfterAppUpdate(timestamp: timestamp, newVersion: initializedCurrentVersion)
            return true
        }
        return false
    }

    private func getDayOfWeekLocal(currentDate: Date) -> Int {
        return calendar.component(.weekday, from: currentDate)
    }

    private func getHourOfDayLocal(currentDate: Date) -> Int {
        return calendar.component(.hour, from: currentDate)
    }

    func daysSince(startEventMs: Int64?, endEventMs: Int64) -> Int64? {
        let dayInMs = 1.days.inMilliseconds()
        guard let startEventMs, startEventMs >= 0, endEventMs >= startEventMs else {
            return nil
        }
        let deltaMs: Int64 = endEventMs - startEventMs
        return (deltaMs / dayInMs)
    }
}

private enum FirstWakeType: Int {
    case month = 3 // 0b0011
    case today = 2 // 0b0010
    case neither = 0

    init?(prevTimestampMs: Int64, curTimestampMs: Int64, calendar: Calendar = Calendar.current) {
        let dateA = Date(unixMilliseconds: prevTimestampMs)
        let monthA = calendar.component(.month, from: dateA)
        let yearA = calendar.component(.year, from: dateA)
        let dayA = calendar.component(.day, from: dateA)

        let dateB = Date(unixMilliseconds: curTimestampMs)
        let monthB = calendar.component(.month, from: dateB)
        let yearB = calendar.component(.year, from: dateB)
        let dayB = calendar.component(.day, from: dateB)

        var result = 0
        let isFirstWakeMonth = yearA != yearB || monthA != monthB
        if isFirstWakeMonth {
            result = FirstWakeType.month.rawValue
        }
        if isFirstWakeMonth || dayA != dayB {
            result = result | FirstWakeType.today.rawValue
        }

        self.init(rawValue: result)
    }

    var isFirstWakeMonth: Bool {
        self.rawValue == FirstWakeType.month.rawValue
    }

    var isFirstWakeToday: Bool {
        self.rawValue >= FirstWakeType.today.rawValue
    }
}

extension Bundle {
    var version: String? {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ??
            object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}
