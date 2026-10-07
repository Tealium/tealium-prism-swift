//
//  VisitorIdSettingsBuilderTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 25/09/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class VisitorIdSettingsBuilderTests: XCTestCase {
    func test_build_without_setters_returns_empty_configuration() {
        let settings = VisitorIdSettingsBuilder().build()
        XCTAssertEqual(settings, ["configuration": DataObject()])
    }

    func test_setVisitorIdentityKey_sets_configuration_visitor_identity_key() {
        let settings = VisitorIdSettingsBuilder()
            .setVisitorIdentityKey("email")
            .build()
        XCTAssertEqual(settings, ["configuration": ["visitor_identity_key": "email"]])
    }
}
