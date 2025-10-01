//
//  LifecycleConstants.swift
//  tealium-prism
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumPrismCore
#endif

enum LifecycleStateKey {
    static let autotracked = "autotracked"
    static let didDetectCrash = "lifecycle_diddetectcrash"
    static let dayOfWeekLocal = "lifecycle_dayofweek_local"
    static let daysSinceFirstLaunch = "lifecycle_dayssincelaunch"
    static let daysSinceUpdate = "lifecycle_dayssinceupdate"
    static let daysSinceLastWake = "lifecycle_dayssincelastwake"
    static let firstLaunchDate = "lifecycle_firstlaunchdate"
    static let firstLaunchDateMmddyyyy = "lifecycle_firstlaunchdate_MMDDYYYY"
    static let hourOfDayLocal = "lifecycle_hourofday_local"
    static let isFirstLaunch = "lifecycle_isfirstlaunch"
    static let isFirstLaunchUpdate = "lifecycle_isfirstlaunchupdate"
    static let isFirstWakeMonth = "lifecycle_isfirstwakemonth"
    static let isFirstWakeToday = "lifecycle_isfirstwaketoday"
    static let launchCount = "lifecycle_launchcount"
    static let priorSecondsAwake = "lifecycle_priorsecondsawake"
    static let secondsAwake = "lifecycle_secondsawake"
    static let sleepCount = "lifecycle_sleepcount"
    static let totalCrashCount = "lifecycle_totalcrashcount"
    static let totalLaunchCount = "lifecycle_totallaunchcount"
    static let totalSecondsAwake = "lifecycle_totalsecondsawake"
    static let totalSleepCount = "lifecycle_totalsleepcount"
    static let totalWakeCount = "lifecycle_totalwakecount"
    static let type = "lifecycle_type"
    static let updateLaunchDate = "lifecycle_updatelaunchdate"
    static let wakeCount = "lifecycle_wakecount"
    static let lastLaunchDate = "lifecycle_lastlaunchdate"
    static let lastWakeDate = "lifecycle_lastwakedate"
    static let lastSleepDate = "lifecycle_lastsleepdate"
}

enum LifecycleStorageKey {
    static let isActiveSession = "is_active_session"
    static let appVersion = "app_version"
    static let timestampUpdate = "timestamp_update"
    static let timestampFirstLaunch = "timestamp_first_launch"
    static let timestampLastLaunch = "timestamp_last_launch"
    static let timestampLastWake = "timestamp_last_wake"
    static let timestampLastSleep = "timestamp_last_sleep"
    static let countLaunch = "count_launch"
    static let countSleep = "count_sleep"
    static let countWake = "count_wake"
    static let countTotalCrash = "count_total_crash"
    static let countTotalLaunch = "count_total_launch"
    static let countTotalSleep = "count_total_sleep"
    static let countTotalWake = "count_total_wake"
    static let lastEvent = "last_event"
    static let totalSecondsAwake = "total_seconds_awake"
    static let priorSecondsAwake = "prior_seconds_awake"
}

extension LogCategory {
    static let lifecycle = "Lifecycle"
}

enum LifecycleConstants {
    static let infiniteSession: Int = -1
}

public extension Modules.Types {
    static let lifecycle = "Lifecycle"
}
