//
//  SettingsManagerTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class SettingsManagerTests: SettingsManagerTestCase {

    func addMockDispatcher() {
        config.addModule(MockDispatcher.factory(enforcedSettings: ModuleSettingsBuilder()
            .setProperty("value", key: "key")
            .build()))
    }

    func test_init_fills_current_settings_with_programmatic() throws {
        addMockDispatcher()
        let manager = try getManager()
        let settings = manager.settings.value
        XCTAssertEqual(settings.modules[MockDispatcher.moduleType]?.configuration, ["key": "value"])
    }

    func test_init_fills_current_settings_with_local_and_programmatic() throws {
        addMockDispatcher()
        let manager = try setupForLocal()
        let settings = manager.settings.value
        XCTAssertEqual(settings.modules[MockDispatcher.moduleType]?.configuration, ["key": "value"])
        XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
    }

    func test_init_fills_current_settings_with_local_cached_and_programmatic() throws {
        addMockDispatcher()
        let cacher = try createCacher()
        try cacher.saveResource([
            "modules": buildModulesSettings(moduleType: "cached",
                                            additionalProperties: ["key": "value"])
        ], etag: nil)
        let manager = try setupForLocal(url: "someUrl")
        let settings = manager.settings.value
        XCTAssertEqual(settings.modules[MockDispatcher.moduleType]?.configuration, ["key": "value"])
        XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
        XCTAssertEqual(settings.modules["cached"]?.configuration, ["key": "value"])
    }

    func test_init_without_url_fills_current_settings_with_local_and_programmatic() throws {
        addMockDispatcher()
        let cacher = try createCacher()
        try cacher.saveResource(["modules": buildModulesSettings(moduleType: "cached",
                                                                 additionalProperties: ["key": "value"])],
                                etag: nil)
        let manager = try setupForLocal()
        let settings = manager.settings.value
        XCTAssertEqual(settings.modules[MockDispatcher.moduleType]?.configuration, ["key": "value"])
        XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
    }

    func test_refresh_fills_merged_settings_with_local_remote_and_programmatic() throws {
        addMockDispatcher()
        let remoteResponse = DataObject(dictionary: [
            "modules": buildModulesSettings(moduleType: "remote",
                                            additionalProperties: ["key": "value"])
        ])
        let manager = try setupForLocalAndRemote(codableResult: .success(.successful(object: remoteResponse)))
        let settings = manager.settings.value
        XCTAssertEqual(settings.modules[MockDispatcher.moduleType]?.configuration, ["key": "value"])
        XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
        XCTAssertEqual(settings.modules["remote"]?.configuration, ["key": "value"])
    }

    func test_failed_refresh_doesnt_fill_merged_settings_with_remote() throws {
        addMockDispatcher()
        let manager = try setupForLocalAndRemote(codableResult: .failure(.non200Status(404)))
        let settings = manager.settings.value
        XCTAssertEqual(settings.modules[MockDispatcher.moduleType]?.configuration, ["key": "value"])
        XCTAssertEqual(settings.modules["localModule"]?.configuration, ["localKey": "localValue"])
    }

    func test_onNewSettingsMerged_doesnt_publish_merged_settings_without_remote_refresh() throws {
        let settingsRefreshed = expectation(description: "Settings should not be refreshed")
        settingsRefreshed.isInverted = true
        addMockDispatcher()
        let manager = try setupForLocal(url: "someUrl")
        guard let refresher = manager.resourceRefresher else {
            XCTFail("Refresher unexpectedly found nil")
            return
        }
        _ = manager.onNewSettingsMerged(resourceRefresher: refresher)
            .subscribe { _ in
                settingsRefreshed.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_onNewSettingsMerged_publishes_merged_settings_on_remote_refresh() throws {
        let settingsRefreshed = expectation(description: "Settings are refreshed")
        addMockDispatcher()
        networkHelper.codableResult = .success(.successful(object: DataObject(dictionary: [
            "modules": buildModulesSettings(moduleType: "remote",
                                            additionalProperties: ["key": "value"])
        ])))
        let manager = try setupForLocal(url: "someUrl")
        guard let refresher = manager.resourceRefresher else {
            XCTFail("Refresher unexpectedly found nil")
            return
        }
        let localRule = try localRules()
        let localTransformation = try self.localTransformation()
        let expectedModules = buildModulesSettings(moduleType: MockDispatcher.moduleType,
                                                   additionalProperties: ["key": "value"]) // Programmatic settings
        + buildModulesSettings(moduleType: "localModule",
                               additionalProperties: ["localKey": "localValue"]) // Local file settings
        + buildModulesSettings(moduleType: "remote",
                               additionalProperties: ["key": "value"]) // Remote settings
        _ = manager.onNewSettingsMerged(resourceRefresher: refresher)
            .subscribe { settings in
                XCTAssertEqual(settings, [
                    "modules": expectedModules,
                    "load_rules": [
                        "localRule": localRule
                    ],
                    "transformations": [
                        "transformerId-transformationId": localTransformation
                    ]
                ])
                settingsRefreshed.fulfill()
            }
        manager.startRefreshing(onActivity: onActivity.asObservable())
        waitForDefaultTimeout()
    }

    func test_onNewSettingsMerged_doesnt_publish_merged_settings_on_failed_remote_refresh() throws {
        let settingsRefreshed = expectation(description: "Settings should not be refreshed")
        settingsRefreshed.isInverted = true
        addMockDispatcher()
        let manager = try setupForLocalAndRemote(codableResult: .failure(.non200Status(404)))
        guard let refresher = manager.resourceRefresher else {
            XCTFail("Refresher unexpectedly found nil")
            return
        }
        _ = manager.onNewSettingsMerged(resourceRefresher: refresher)
            .subscribe { _ in
                settingsRefreshed.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_onNewRefreshInterval_publishes_new_interval_when_it_changes() throws {
        let refreshIntervalUpdated = expectation(description: "RefreshInterval is updated")
        refreshIntervalUpdated.expectedFulfillmentCount = 2
        addMockDispatcher()
        networkHelper.codableResult = .success(.successful(object: DataObject(dictionary: [CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: Double(100)]])))
        let manager = try setupForLocal(url: "someUrl")
        var firstInterval = true
        _ = manager.onNewRefreshInterval().subscribe { newInterval in
            if firstInterval {
                firstInterval = false
                XCTAssertEqual(newInterval, 900.seconds)
            } else {
                XCTAssertEqual(newInterval, 100.seconds)
            }
            refreshIntervalUpdated.fulfill()
        }
        manager.startRefreshing(onActivity: onActivity.asObservable())
        waitForDefaultTimeout()
    }

    func test_onNewRefreshInterval_doesnt_publish_new_interval_when_it_doesnt_change() throws {
        let refreshIntervalUpdated = expectation(description: "RefreshInterval is updated only once")
        addMockDispatcher()
        let manager = try setupForLocal(url: "someUrl")
        let sdkSettings: DataObject = ["modules": [
            CoreSettings.id: [CoreSettings.Keys.refreshIntervalSeconds: CoreSettings.Defaults.refreshInterval.inSeconds()]
        ]]
        networkHelper.codableResult = .success(.successful(object: sdkSettings))
        _ = manager.onNewRefreshInterval().subscribe { newInterval in
            XCTAssertEqual(newInterval, 900.seconds)
            refreshIntervalUpdated.fulfill()
        }
        manager.startRefreshing(onActivity: onActivity.asObservable())
        waitForDefaultTimeout()
    }

    func test_onShouldRequestRefresh_requests_refreshes_on_launch_and_foreground() {
        let refreshShouldBeRequested = expectation(description: "Refresh should be requested")
        refreshShouldBeRequested.expectedFulfillmentCount = 2
        let publisher = BasePublisher<ApplicationStatus>()
        _ = SettingsManager.onShouldRequestRefresh(publisher.asObservable())
            .subscribe {
                refreshShouldBeRequested.fulfill()
            }
        publisher.publish(ApplicationStatus(type: .foregrounded))
        waitForDefaultTimeout()
    }

    func test_onShouldRequestRefresh_doesnt_request_refreshes_on_background() {
        let refreshShouldNotBeRequestedOnBackground = expectation(description: "Refresh should be requested on launch but not on background")
        let publisher = BasePublisher<ApplicationStatus>()
        _ = SettingsManager.onShouldRequestRefresh(publisher.asObservable())
            .subscribe {
                refreshShouldNotBeRequestedOnBackground.fulfill()
            }
        publisher.publish(ApplicationStatus(type: .backgrounded))
        waitForDefaultTimeout()
    }

    func test_loadLocalSettings_returns_bundled_settings() throws {
        config.bundle = Bundle(for: type(of: self))
        let localSettings = SettingsManager.loadLocalSettings(config: config)
        XCTAssertNotNil(localSettings)
        XCTAssertEqual(localSettings, [
            "modules": buildModulesSettings(moduleType: "localModule",
                                            additionalProperties: ["localKey": "localValue"]),
            "load_rules": [
                "localRule": try localRules()
            ],
            "transformations": [
                "transformerId-transformationId": try localTransformation()
            ]
        ])
    }

    func test_startRefreshing_only_starts_once() throws {
        let settingsUpdatedOnlyOnce = expectation(description: "Settings are updated only at init and on one refresh even if we start refreshing multiple times")
        settingsUpdatedOnlyOnce.expectedFulfillmentCount = 2
        let settings: DataObject = [
            CoreSettings.id: [
                "configuration": [CoreSettings.Keys.refreshIntervalSeconds: Double(0)]
            ]
        ]
        networkHelper.codableResult = .success(.successful(object: settings))
        let manager = try getManager(url: "someUrl")
        _ = manager.settings.subscribe { _ in
            settingsUpdatedOnlyOnce.fulfill()
        }
        func newSettings(count: Int) -> DataObject {
            SettingsManager.merge(orderedSettings: [settings, [
                "modules": buildModulesSettings(moduleType: "remote",
                                                additionalProperties: ["key": "value"])

            ]])
        }
        for count in 0..<3 {
            networkHelper.codableResult = .success(.successful(object: newSettings(count: count)))
            manager.startRefreshing(onActivity: Observable.Empty())
        }
        waitForDefaultTimeout()
    }

    func test_merge_merges_loadRules() throws {
        config.bundle = Bundle(for: type(of: self))
        let condition = Condition(path: nil, variable: "variable", operator: .equals(true), filter: "value")
        config.setLoadRule(.just(condition), forId: "programmaticRule")
        let manager = try getManager()
        let settings = manager.settings.value
        guard case let .just(item) = settings.loadRules["programmaticRule"]?.conditions else {
            XCTFail("Failed to extract programmatic JUST rule")
            return
        }
        XCTAssertEqual(item as? Condition, condition)
        guard case let .and(children) = settings.loadRules["localRule"]?.conditions else {
            XCTFail("Failed to extract local AND rule")
            return
        }
        guard case let .just(localItem) = children.first else {
            XCTFail("Failed to extract local JUST rule")
            return
        }
        XCTAssertEqual(localItem as? Condition, Condition(path: nil, variable: "variable", operator: .isDefined, filter: nil))
    }
}
