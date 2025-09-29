//
//  UpdateLaunchTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 21/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class UpdateLaunchTests: LifecycleServiceBaseTests {
    var customEventTimestamp: Int64 { launchTimestamp + millisecondsPerDay + millisecondsPerHour }

    override func setUpWithError() throws {
        try super.setUpWithError()
        try lifecycleStorage.setCurrentAppVersion(newVersion: "0.9")
        lifecycleEventState = try lifecycleService.registerLaunch(timestamp: launchTimestamp)
        customEventState = lifecycleService.getCurrentState(timestamp: customEventTimestamp)
    }

    func test_didDetectCrash_is_only_defined_on_first_launch_after_crash() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.didDetectCrash))
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.didDetectCrash))
    }

    func test_dayOfWeekLocal_equals_eventTimestamp_weekday() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.dayOfWeekLocal)?.get(), lifecycleService.calendar
            .component(.weekday, from: Date(unixMilliseconds: launchTimestamp)))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.dayOfWeekLocal)?.get(), lifecycleService.calendar
            .component(.weekday, from: Date(unixMilliseconds: customEventTimestamp)))
    }

    func test_hourOfDayLocal_equals_eventTimestamp_hour() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.hourOfDayLocal)?.get(), lifecycleService.calendar
            .component(.hour, from: Date(unixMilliseconds: launchTimestamp)))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.hourOfDayLocal)?.get(), lifecycleService.calendar
            .component(.hour, from: Date(unixMilliseconds: customEventTimestamp)))
    }

    func test_daysSinceLaunch_is_the_difference_between_event_dates_and_launch_date_in_days() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.daysSinceFirstLaunch)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.daysSinceFirstLaunch)?.get(), 1)
    }

    func test_daysSinceUpdate_is_the_difference_between_event_dates_and_launch_update_date_in_days() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.daysSinceUpdate)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.daysSinceUpdate)?.get(), 1)
    }

    func test_daysSinceLastWake_is_the_difference_between_event_dates_and_last_launch_or_wake_date_in_days() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.daysSinceLastWake))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.daysSinceLastWake)?.get(), 1)
    }

    func test_firstLaunchDate_is_the_dateString_of_the_first_launch_after_install() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.firstLaunchDate)?.get(), launchDateString)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.firstLaunchDate)?.get(), launchDateString)
    }

    func test_firstLaunchDateMmddyyyy_is_mmddyyyy_dateString_of_first_launch_after_install() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.firstLaunchDateMmddyyyy)?.get(), launchMmDdYyyyString)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.firstLaunchDateMmddyyyy)?.get(), launchMmDdYyyyString)
    }

    func test_isFirstLaunch_is_only_defined_on_first_launch_event() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.isFirstLaunch)?.get(), true)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstLaunch))
    }

    func test_isFirstLaunchUpdate_is_only_defined_on_first_launch_event_after_update() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.isFirstLaunchUpdate)?.get(), true)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstLaunchUpdate))
    }

    func test_isFirstWakeMonth_is_only_defined_on_first_launch_or_wake_of_the_month() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.isFirstWakeMonth)?.get(), true)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstWakeMonth))
    }

    func test_isFirstWakeToday_is_only_defined_on_first_launch_or_wake_of_the_day() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.isFirstWakeToday)?.get(), true)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstWakeToday))
    }

    func test_launchCount_is_increased_on_every_launch_and_does_not_change_on_other_events() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.launchCount)?.get(), 1)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.launchCount)?.get(), 1)
    }

    func test_priorSecondsAwake_is_only_defined_on_launch_events_and_is_the_seconds_the_app_was_awake_during_last_session() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.priorSecondsAwake)?.get(), 0)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.priorSecondsAwake))
    }

    func test_secondsAwake_is_aggregate_seconds_app_was_in_foreground_until_current_event_during_this_session() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.secondsAwake))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.secondsAwake)?.get(), secondsPerDay + secondsPerHour)
    }

    func test_sleepCount_is_increased_on_every_sleep_and_does_not_change_on_other_events() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.sleepCount)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.sleepCount)?.get(), 0)
    }

    func test_totalCrashCount_is_only_increased_when_a_launch_follows_another_launch_or_wake() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalCrashCount)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalCrashCount)?.get(), 0)
    }

    func test_totalLaunchCount_is_increased_on_every_launch_and_does_not_change_on_other_events() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalLaunchCount)?.get(), 1)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalLaunchCount)?.get(), 1)
    }

    func test_totalSecondsAwake_is_aggregate_seconds_app_was_in_foreground_until_current_event_since_install() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalSecondsAwake)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalSecondsAwake)?.get(), secondsPerDay + secondsPerHour)
    }

    func test_totalSleepCount_is_increased_on_every_sleep_and_does_not_change_on_other_events() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalSleepCount)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalSleepCount)?.get(), 0)
    }

    func test_totalWakeCount_is_increased_on_every_launch_and_wake_and_does_not_change_on_other_events() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalWakeCount)?.get(), 1)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalWakeCount)?.get(), 1)
    }

    func test_updateLaunchDate_is_date_of_first_launch_after_update() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.updateLaunchDate)?.get(), launchDateString)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.updateLaunchDate)?.get(), launchDateString)
    }

    func test_type_is_the_event_type_for_lifecycle_events_and_not_defined_for_custom_ones() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.type)?.get(), LifecycleEvent.launch.rawValue)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.type))
    }

    func test_wakeCount_is_increased_on_every_launch_and_wake_and_does_not_change_on_other_events() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.wakeCount)?.get(), 1)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.wakeCount)?.get(), 1)
    }

    func test_lastLaunchDate_is_dateString_of_last_launch_happened_before_current_event() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.lastLaunchDate))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.lastLaunchDate)?.get(), launchDateString)
    }

    func test_lastSleepDate_is_dateString_of_last_sleep_happened_before_current_event() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.lastSleepDate))
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.lastSleepDate))
    }

    func test_lastWakeDate_is_dateString_of_last_launch_or_wake_happened_before_current_event() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.lastWakeDate))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.lastWakeDate)?.get(), launchDateString)
    }
}
