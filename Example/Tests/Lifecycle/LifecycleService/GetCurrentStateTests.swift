//
//  GetCurrentStateTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 19/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class GetCurrentStateTests: LifecycleServiceBaseTests {
    override func setUpWithError() throws {
        try super.setUpWithError()
        customEventState = lifecycleService.getCurrentState(timestamp: launchTimestamp)
    }

    func test_didDetectCrash_is_never_defined_on_non_launch_events() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.didDetectCrash))
    }

    func test_dayOfWeekLocal_equals_eventTimestamp_weekday() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.dayOfWeekLocal)?.get(), lifecycleService.calendar
            .component(.weekday, from: Date(unixMilliseconds: launchTimestamp)))
    }

    func test_hourOfDayLocal_equals_eventTimestamp_hour() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.hourOfDayLocal)?.get(), lifecycleService.calendar
            .component(.hour, from: Date(unixMilliseconds: launchTimestamp)))
    }

    func test_daysSinceLaunch_is_not_defined_until_a_first_launch() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.daysSinceFirstLaunch))
    }

    func test_daysSinceUpdate_is_never_defined_if_there_were_no_updates_since_install() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.daysSinceUpdate))
    }

    func test_daysSinceLastWake_is_not_defined_until_a_first_launch() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.daysSinceLastWake))
    }

    func test_firstLaunchDate_is_the_dateString_of_the_first_event_even_if_not_launch() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.firstLaunchDate)?.get(), launchDateString)
    }

    func test_firstLaunchDateMmddyyyy_is_mmddyyyy_dateString_of_the_first_event_even_if_not_launch() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.firstLaunchDateMmddyyyy)?.get(), launchMmDdYyyyString)
    }

    func test_isFirstLaunch_is_never_defined_on_non_launch_events() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstLaunch))
    }

    func test_isFirstLaunchUpdate_is_never_defined_on_non_launch_events() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstLaunchUpdate))
    }

    func test_isFirstWakeMonth_is_never_defined_on_custom_events() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstWakeMonth))
    }

    func test_isFirstWakeToday_is_never_defined_on_custom_events() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstWakeToday))
    }

    func test_launchCount_is_not_increased_on_custom_events() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.launchCount)?.get(), 0)
    }

    func test_priorSecondsAwake_is_never_defined_on_non_launch_events() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.priorSecondsAwake))
    }

    func test_secondsAwake_is_zero_if_there_was_no_launch_or_wake() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.secondsAwake)?.get(), 0)
    }

    func test_sleepCount_is_zero_if_there_was_no_sleep() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.sleepCount)?.get(), 0)
    }

    func test_totalCrashCount_is_only_increased_when_a_launch_follows_another_launch_or_wake() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalCrashCount)?.get(), 0)
    }

    func test_totalLaunchCount_is_increased_on_every_launch_and_does_not_change_on_other_events() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalLaunchCount)?.get(), 0)
    }

    func test_totalSecondsAwake_is_aggregate_seconds_app_was_in_foreground_until_current_event_since_install() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalSecondsAwake)?.get(), 0)
    }

    func test_totalSleepCount_is_increased_on_every_sleep_and_does_not_change_on_other_events() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalSleepCount)?.get(), 0)
    }

    func test_totalWakeCount_is_increased_on_every_launch_and_wake_and_does_not_change_on_other_events() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalWakeCount)?.get(), 0)
    }

    func test_updateLaunchDate_is_not_defined_if_there_were_no_updates_since_install() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.updateLaunchDate))
    }

    func test_type_is_not_defined_for_custom_events() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.type))
    }

    func test_wakeCount_is_increased_on_every_launch_and_wake_and_does_not_change_on_other_events() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.wakeCount)?.get(), 0)
    }

    func test_lastLaunchDate_is_never_defined_if_there_was_no_launch() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.lastLaunchDate))
    }

    func test_lastSleepDate_is_never_defined_if_there_was_no_sleep() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.lastSleepDate))
    }

    func test_lastWakeDate_is_never_defined_if_there_was_no_launch_or_wake() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.lastWakeDate))
    }
}
