//
//  LifecycleSettingsBuilderTests.swift
//  LifecycleTests_iOS
//
//  Created by Den Guzov on 25/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class LifecycleSettingsBuilderTests: XCTestCase {
    func test_build_without_setters_returns_empty_configuration() {
        let settings = LifecycleSettingsBuilder().build()
        XCTAssertEqual(settings, [
            "configuration": DataObject()
        ])
    }

    func test_build_returns_correct_module_settings() throws {
        let settings = LifecycleSettingsBuilder()
            .setEnabled(true)
            .setAutoTrackingEnabled(false)
            .setDataTarget(.allEvents)
            .setSessionTimeoutInMinutes(1)
            .setTrackedLifecycleEvents([])
            .build()
        XCTAssertEqual(settings,
                       [
                        "enabled": true,
                        "configuration":
                            try DataItem(serializing: [
                                "autotracking_enabled": false,
                                "data_target": "allEvents",
                                "session_timeout": 1,
                                "tracked_lifecycle_events": [String]()
                            ])
                       ])
    }
}
