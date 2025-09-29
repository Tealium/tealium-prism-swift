//
//  DeepLinkSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 16/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DeepLinkSettingsBuilderTests: XCTestCase {
    func test_build_without_setters_returns_empty_configuration() {
        let settings = DeepLinkSettingsBuilder().build()
        XCTAssertEqual(settings, ["configuration": DataObject()])
    }

    func test_build_returns_correct_module_settings() throws {
        let settings = DeepLinkSettingsBuilder()
            .setEnabled(true)
            .setDeepLinkTraceEnabled(false)
            .setSendDeepLinkEvent(true)
            .build()
        XCTAssertEqual(settings,
                       [
                        "enabled": true,
                        "configuration":
                            try DataItem(serializing: [
                                "deep_link_trace_enabled": false,
                                "send_deep_link_event": true
                            ])
                       ])
    }
}
