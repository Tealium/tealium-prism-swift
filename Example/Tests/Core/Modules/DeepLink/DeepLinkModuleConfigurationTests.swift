//
//  DeepLinkModuleConfigurationTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 16/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DeepLinkModuleConfigurationTests: XCTestCase {
    func test_init_with_empty_object_returns_settings_with_correct_defaults() {
        let configuration = DeepLinkModuleConfiguration(configuration: [:])
        XCTAssertEqual(configuration.deepLinkTraceEnabled, true)
        XCTAssertEqual(configuration.sendDeepLinkEvent, false)
    }

    func test_init_with_dataObject_returns_correct_configuration() {
        let configuration = DeepLinkModuleConfiguration(configuration: [
            "deep_link_trace_enabled": false,
            "send_deep_link_event": true
        ])
        XCTAssertEqual(configuration.deepLinkTraceEnabled, false)
        XCTAssertEqual(configuration.sendDeepLinkEvent, true)
    }
}
