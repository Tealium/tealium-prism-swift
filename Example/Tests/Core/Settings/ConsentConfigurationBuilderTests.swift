//
//  ConsentConfigurationBuilderTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConsentConfigurationBuilderTests: XCTestCase {

    func test_build_returns_consent_moduleSettings() throws {
        let configuration = ConsentConfigurationBuilder()
                .setTealiumPurposeId("tealium")
                .addPurpose("purpose1", dispatcherIds: ["dispatcherId1"])
                .addPurpose("purpose2", dispatcherIds: ["dispatcherId2"])
                .setRefireDispatchersIds(["refireDispatcher"])
                .build()
        XCTAssertEqual(configuration, [
            "tealium_purpose_id": "tealium",
            "purposes": try DataItem(serializing: [
                "purpose1": [
                    "purpose_id": "purpose1",
                    "dispatcher_ids": ["dispatcherId1"]
                ],
                "purpose2": [
                    "purpose_id": "purpose2",
                    "dispatcher_ids": ["dispatcherId2"]
                ]
            ]),
            "refire_dispatcher_ids": ["refireDispatcher"]
        ])
    }

    func test_build_without_setters_returns_empty_settings() {
        let configuration = ConsentConfigurationBuilder().build()
        XCTAssertEqual(configuration, [:])
    }
}
