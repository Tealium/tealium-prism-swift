//
//  TealiumConfig+BarriersTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 09/01/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TealiumConfigBarriersTests: TealiumConfigBaseTests {

    func test_getEnforcedSDKSettings_includes_barrier_settings() {
        config.addBarrier(MockBarrierFactory<MockBarrier1>(defaultScopes: [.all], enforcedSettings: [
            "batch_size": 5,
            "scopes": ["all"]
        ]))
        let settings = config.getEnforcedSDKSettings()
        let barrier1Settings = settings.getDataDictionary(key: "barriers")?["barrier1"]?.getDataDictionary()

        XCTAssertEqual(barrier1Settings?.get(key: "barrier_id"), "barrier1")
    }

    func test_getEnforcedSDKSettings_with_multiple_barriers() {
        config.addBarrier(MockBarrierFactory<MockBarrier1>(defaultScopes: [.all], enforcedSettings: [
            "batch_size": 3
        ]))
        config.addBarrier(MockBarrierFactory<MockBarrier2>(defaultScopes: [.dispatcher(id: "test")], enforcedSettings: [
            "wifi_only": true
        ]))
        let settings = config.getEnforcedSDKSettings()
        let barriersSettings = settings.getDataDictionary(key: "barriers")

        XCTAssertEqual(barriersSettings?.keys.count, 2)
        XCTAssertTrueOptional(barriersSettings?.keys.contains("barrier1"))
        XCTAssertTrueOptional(barriersSettings?.keys.contains("barrier2"))
    }

    func test_getEnforcedSDKSettings_without_barriers() {
        let settings = config.getEnforcedSDKSettings()

        XCTAssertNil(settings.getDataDictionary(key: "barriers"))
    }

    func test_getEnforcedSDKSettings_with_barriers_without_enforced_settings() {
        config.addBarrier(MockBarrierFactory<MockBarrier1>(defaultScopes: [.all]))
        let settings = config.getEnforcedSDKSettings()

        XCTAssertNil(settings.getDataDictionary(key: "barriers"))
    }

    func test_barrier_settings_prefer_first_when_duplicate_ids() {
        config.addBarrier(MockBarrierFactory<MockBarrier1>(defaultScopes: [.all], enforcedSettings: [
            "batch_size": 5
        ]))
        config.addBarrier(MockBarrierFactory<MockBarrier1>(defaultScopes: [.all], enforcedSettings: [
            "batch_size": 10
        ]))
        let settings = config.getEnforcedSDKSettings()
        let barriersSettings = settings.getDataDictionary(key: "barriers")

        XCTAssertEqual(barriersSettings?.keys.count, 1)
        let barrier1Settings = barriersSettings?["barrier1"]?.getDataDictionary()
        XCTAssertEqual(barrier1Settings?.get(key: "batch_size"), 5)
    }
}
