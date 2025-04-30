//
//  DeepLinkConfigurationTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 16/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DeepLinkConfigurationTests: XCTestCase {
    func test_init_with_empty_object_returns_settings_with_correct_defaults() {
        let configuration = DeepLinkHandlerConfiguration(configuration: [:])
        XCTAssertEqual(configuration.qrTraceEnabled, true)
        XCTAssertEqual(configuration.sendDeepLinkEvent, false)
    }

    func test_init_with_dataObject_returns_correct_configuration() {
        let configuration = DeepLinkHandlerConfiguration(configuration: [
            "qr_trace_enabled": false,
            "send_deep_link_event": true
        ])
        XCTAssertEqual(configuration.qrTraceEnabled, false)
        XCTAssertEqual(configuration.sendDeepLinkEvent, true)
    }
}
