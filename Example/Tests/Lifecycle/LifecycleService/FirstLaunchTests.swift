//
//  FirstLaunchTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 28/10/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class FirstLaunchTests: LifecycleServiceBaseTests {
    var customEventTimestamp: Int64 { launchTimestamp + millisecondsPerDay }

    override func setUpWithError() throws {
        try super.setUpWithError()
        lifecycleEventState = try lifecycleService.registerLaunch(timestamp: launchTimestamp)
        customEventState = lifecycleService.getCurrentState(timestamp: customEventTimestamp)
    }

    func test_didDetectCrash_is_correct() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.didDetectCrash))
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.didDetectCrash))
    }

    func test_dayOfWeekLocal_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.dayOfWeekLocal)?.get(), lifecycleService.calendar
            .component(.weekday, from: Date(unixMilliseconds: launchTimestamp)))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.dayOfWeekLocal)?.get(), lifecycleService.calendar
            .component(.weekday, from: Date(unixMilliseconds: customEventTimestamp)))
    }

    func test_daysSinceLaunch_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.daysSinceFirstLaunch)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.daysSinceFirstLaunch)?.get(), 1)
    }

    func test_daysSinceUpdate_is_correct() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.daysSinceUpdate))
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.daysSinceUpdate))
    }

    func test_daysSinceLastWake_is_correct() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.daysSinceLastWake))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.daysSinceLastWake)?.get(), 1)
    }

    func test_firstLaunchDate_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.firstLaunchDate)?.get(), launchDateString)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.firstLaunchDate)?.get(), launchDateString)
    }

    func test_firstLaunchDateMmddyyyy_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.firstLaunchDateMmddyyyy)?.get(), launchMmDdYyyyString)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.firstLaunchDateMmddyyyy)?.get(), launchMmDdYyyyString)
    }

    func test_hourOfDayLocal_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.hourOfDayLocal)?.get(), lifecycleService.calendar
            .component(.hour, from: Date(unixMilliseconds: launchTimestamp)))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.hourOfDayLocal)?.get(), lifecycleService.calendar
            .component(.hour, from: Date(unixMilliseconds: customEventTimestamp)))
    }

    func test_isFirstLaunch_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.isFirstLaunch)?.get(), true)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstLaunch))
    }

    func test_isFirstLaunchUpdate_is_correct() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.isFirstLaunchUpdate))
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstLaunchUpdate))
    }

    func test_isFirstWakeMonth_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.isFirstWakeMonth)?.get(), true)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstWakeMonth))
    }

    func test_isFirstWakeToday_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.isFirstWakeToday)?.get(), true)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.isFirstWakeToday))
    }

    func test_launchCount_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.launchCount)?.get(), 1)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.launchCount)?.get(), 1)
    }

    func test_priorSecondsAwake_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.priorSecondsAwake)?.get(), 0)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.priorSecondsAwake))
    }

    func test_secondsAwake_is_correct() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.secondsAwake))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.secondsAwake)?.get(), secondsPerDay)
    }

    func test_sleepCount_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.sleepCount)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.sleepCount)?.get(), 0)
    }

    func test_totalCrashCount_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalCrashCount)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalCrashCount)?.get(), 0)
    }

    func test_totalLaunchCount_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalLaunchCount)?.get(), 1)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalLaunchCount)?.get(), 1)
    }

    func test_totalSecondsAwake_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalSecondsAwake)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalSecondsAwake)?.get(), secondsPerDay)
    }

    func test_totalSleepCount_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalSleepCount)?.get(), 0)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalSleepCount)?.get(), 0)
    }

    func test_totalWakeCount_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.totalWakeCount)?.get(), 1)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.totalWakeCount)?.get(), 1)
    }

    func test_updateLaunchDate_is_correct() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.updateLaunchDate))
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.updateLaunchDate))
    }

    func test_type_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.type)?.get(), LifecycleEvent.launch.rawValue)
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.type))
    }

    func test_wakeCount_is_correct() {
        XCTAssertEqual(lifecycleEventState.getDataItem(key: LifecycleStateKey.wakeCount)?.get(), 1)
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.wakeCount)?.get(), 1)
    }

    func test_lastLaunchDate_is_correct() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.lastLaunchDate))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.lastLaunchDate)?.get(), launchDateString)
    }

    func test_lastSleepDate_is_correct() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.lastSleepDate))
        XCTAssertNil(customEventState.getDataItem(key: LifecycleStateKey.lastSleepDate))
    }

    func test_lastWakeDate_is_correct() {
        XCTAssertNil(lifecycleEventState.getDataItem(key: LifecycleStateKey.lastWakeDate))
        XCTAssertEqual(customEventState.getDataItem(key: LifecycleStateKey.lastWakeDate)?.get(), launchDateString)
    }
}
