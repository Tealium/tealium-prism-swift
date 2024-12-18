//
//  GetCurrentStateTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 19/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest
// TODO: check tests naming after Enrico's change here and in other files
final class GetCurrentStateTests: LifecycleServiceBaseTests {
    override func setUpWithError() throws {
        try super.setUpWithError()
        customEventState = lifecycleService.getCurrentState(timestamp: launchTimestamp)
    }

    func test_didDetectCrash_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.didDetectCrash))
    }

    func test_dayOfWeekLocal_is_correct_number() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.dayOfWeekLocal)?.get(), lifecycleService.calendar
            .component(.weekday, from: Date(unixMilliseconds: launchTimestamp)))
    }

    func test_daysSinceLaunch_is_zero() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.daysSinceFirstLaunch))
    }

    func test_daysSinceUpdate_is_zero() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.daysSinceUpdate))
    }

    func test_daysSinceLastWake_is_zero() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.daysSinceLastWake))
    }

    func test_firstLaunchDate_is_correct_string() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.firstLaunchDate)?.get(), launchDateString)
    }

    func test_firstLaunchDateMmddyyyy_is_correct_string() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.firstLaunchDateMmddyyyy)?.get(), launchMmDdYyyyString)
    }

    func test_hourOfDayLocal_is_correct_number() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.hourOfDayLocal)?.get(), lifecycleService.calendar
            .component(.hour, from: Date(unixMilliseconds: launchTimestamp)))
    }

    func test_isFirstLaunch_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstLaunch))
    }

    func test_isFirstLaunchUpdate_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstLaunchUpdate))
    }

    func test_isFirstWakeMonth_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstWakeMonth))
    }

    func test_isFirstWakeToday_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstWakeToday))
    }

    func test_launchCount_is_zero() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.launchCount)?.get(), 0)
    }

    func test_priorSecondsAwake_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.priorSecondsAwake))
    }

    func test_secondsAwake_is_zero() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.secondsAwake)?.get(), 0)
    }

    func test_sleepCount_is_zero() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.sleepCount)?.get(), 0)
    }

    func test_totalCrashCount_is_zero() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalCrashCount)?.get(), 0)
    }

    func test_totalLaunchCount_is_zero() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalLaunchCount)?.get(), 0)
    }

    func test_totalSecondsAwake_is_zero() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalSecondsAwake)?.get(), 0)
    }

    func test_totalSleepCount_is_zero() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalSleepCount)?.get(), 0)
    }

    func test_totalWakeCount_is_zero() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalWakeCount)?.get(), 0)
    }

    func test_updateLaunchDate_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.updateLaunchDate))
    }

    func test_type_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.type))
    }

    func test_wakeCount_is_zero() {
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.wakeCount)?.get(), 0)
    }

    func test_lastLaunchDate_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.lastLaunchDate))
    }

    func test_lastSleepDate_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.lastSleepDate))
    }

    func test_lastWakeDate_is_nil() {
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.lastWakeDate))
    }
}
