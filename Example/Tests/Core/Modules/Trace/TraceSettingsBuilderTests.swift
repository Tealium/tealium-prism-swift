//
//  TraceSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 28/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TraceSettingsBuilderTests: XCTestCase {

    func test_build_returns_trace_moduleSettings() {
        let settings = TraceSettingsBuilder()
            .setTrackErrors(true)
            .setEnabled(true)
            .build()
        XCTAssertEqual(settings, [
            "configuration": [
                "track_errors": true,
            ],
            "enabled": true
        ])
    }

    func test_build_without_setters_returns_empty_configuration() {
        let settings = TraceSettingsBuilder().build()
        XCTAssertEqual(settings, ["configuration": DataObject()])
    }
}
