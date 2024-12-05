//
//  SDKSettingsTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class SDKSettingsTests: XCTestCase {

    func test_encoded_settings_is_decoded_to_same_settings() throws {
        let settings = SDKSettings(modulesSettings: ["module1": [
            "key1": "value1",
            "key2": 25,
            "key3": [
                "something"
            ],
            "key4": [
                "key5": "something"
            ]
        ]])
        let data = try Tealium.jsonEncoder.encode(settings)
        let decodedSettings = try Tealium.jsonDecoder.decode(SDKSettings.self, from: data)
        XCTAssertEqual(settings.modulesSettings, decodedSettings.modulesSettings)
    }

    func test_wrong_data_fails_to_decode_to_settings() throws {
        let object = ["key1": "value1"]
        let data = try Tealium.jsonEncoder.encode(object)
        XCTAssertThrowsError(try Tealium.jsonDecoder.decode(SDKSettings.self, from: data))
    }
}
