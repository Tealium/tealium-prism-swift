//
//  TraceModuleConfigurationTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 28/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TraceModuleConfigurationTests: XCTestCase {
    func test_init_with_empty_object_returns_settings_with_correct_defaults() {
        let configuration = TraceModuleConfiguration(configuration: [:])
        XCTAssertEqual(configuration.trackErrors, TraceModuleConfiguration.Defaults.trackErrors)
    }

    func test_init_with_dataObject_returns_correct_configuration() {
        let configuration = TraceModuleConfiguration(configuration: [
            "track_errors": true
        ])
        XCTAssertEqual(configuration.trackErrors, true)
    }
}
