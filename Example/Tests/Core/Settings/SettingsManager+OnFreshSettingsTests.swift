//
//  SettingsManager+OnFreshSettingsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SettingsManagerOnFreshSettingsTests: SettingsManagerTestCase {

    func test_onFreshSettings_emits_localSettings_when_no_settingsUrl_provided() throws {
        let settingsEmitted = expectation(description: "Settings are emitted")
        let manager = try setupForLocal()
        manager.onFreshSettings.subscribeOnce { settings in
            XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
            settingsEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onFreshSettings_doesnt_emit_localSettings_when_settingsUrl_provided() throws {
        let settingsEmitted = expectation(description: "Settings are not emitted")
        settingsEmitted.isInverted = true
        let manager = try setupForLocal(url: "someUrl")
        manager.onFreshSettings.subscribeOnce { _ in
            settingsEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onFreshSettings_emits_remoteSettings_when_settingsUrl_provided() throws {
        let settingsEmitted = expectation(description: "Settings are emitted")
        let manager = try setupForLocalAndRemote(codableResult: .success(
            .successful(object: DataObject(dictionary: [
                "modules": buildModulesSettings(moduleType: "remote",
                                                additionalProperties: ["key": "value"])
            ])))
        )
        manager.onFreshSettings.subscribeOnce { settings in
            XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
            XCTAssertEqual(settings.modules["remote"]?.configuration, ["key": "value"])
            settingsEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_failed_refresh_is_reported_with_localSettings_anyway() throws {
        let settingsEmitted = expectation(description: "Settings are emitted")
        let manager = try setupForLocalAndRemote(codableResult: .failure(.non200Status(404)))
        manager.onFreshSettings.subscribeOnce { settings in
            XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
            settingsEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_refresh_completed_with_notModified_statusCode_is_reported_with_localSettings_anyway() throws {
        let settingsEmitted = expectation(description: "Settings are emitted")
        let manager = try setupForLocalAndRemote(codableResult: .failure(.non200Status(304)))
        manager.onFreshSettings.subscribeOnce { settings in
            XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
            settingsEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onFreshSettings_emits_newest_settings_on_every_refresh() throws {
        let settingsEmitted = expectation(description: "Settings are emitted")
        settingsEmitted.expectedFulfillmentCount = 2
        let manager = try setupForLocalAndRemote(codableResult: .success(.successful(object: DataObject(dictionary: [CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: Double(0)]]))))
        manager.onFreshSettings.subscribeOnce { settings in
            XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
            XCTAssertEqual(settings.core.refreshInterval.inSeconds(), 0)
            settingsEmitted.fulfill()
        }
        try networkHelper.encodeResult(DataObject(dictionary: [CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: Double(10)]]))
        onActivity.publish(ApplicationStatus(type: .backgrounded))
        onActivity.publish(ApplicationStatus(type: .foregrounded))
        manager.onFreshSettings.subscribeOnce { settings in
            XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
            XCTAssertEqual(settings.core.refreshInterval.inSeconds(), 10)
            settingsEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onFreshSettings_emits_again_on_every_refresh() throws {
        let settingsEmitted = expectation(description: "Settings are emitted")
        settingsEmitted.expectedFulfillmentCount = 2
        let manager = try setupForLocalAndRemote(codableResult: .success(.successful(object: DataObject(dictionary: [CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: Double(0)]]))))
        var firstEmit = true
        _ = manager.onFreshSettings.subscribe { settings in
            if firstEmit {
                firstEmit = false
                XCTAssertEqual(settings.core.refreshInterval.inSeconds(), 0)
            } else {
                XCTAssertEqual(settings.core.refreshInterval.inSeconds(), 10)
            }
            XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])

            settingsEmitted.fulfill()
        }
        try networkHelper.encodeResult(DataObject(dictionary: [CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: Double(10)]]))
        onActivity.publish(ApplicationStatus(type: .backgrounded))
        onActivity.publish(ApplicationStatus(type: .foregrounded))
        waitForDefaultTimeout()
    }
}
