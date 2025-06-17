//
//  ConsentSettingsTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

extension ConsentSettings {
    init?(configuration: DataObject?) {
        guard let configuration else { return nil }
        self.init(configuration: configuration)
    }
}

final class ConsentSettingsTests: XCTestCase {
    typealias Keys = ConsentSettings.Keys
    func test_configurations_are_set_on_init() {
        let consentSettings = ConsentSettings(settings: DataObject(dictionaryInput: [
            Keys.configurations: [
                "vendorId": [
                    "tealium_purpose_id": "tealium",
                    "purposes": []
                ]
            ]
        ]))
        guard let configuration = consentSettings.configurations["vendorId"] else {
            XCTFail("Configuration not found in \(consentSettings)")
            return
        }
        XCTAssertEqual(configuration.tealiumPurposeId, "tealium")
        XCTAssertEqual(configuration.refireDispatchersIds, [])
        XCTAssertEqual(configuration.purposes, [])
    }

    func test_create_configuration_from_builder_sets_configurations() {
        let builder = ConsentSettingsBuilder(vendorId: "vendorId")
            .setConfiguration(ConsentConfigurationBuilder()
                .setTealiumPurposeId("tealium")
                .setPurposes([])
                .setRefireDispatchersIds(["id"])
            )
        let consentSettings = builder.build()
            .getConvertible(converter: ConsentSettings.converter)
        XCTAssertNotNil(consentSettings?.configurations["vendorId"])
    }
}
