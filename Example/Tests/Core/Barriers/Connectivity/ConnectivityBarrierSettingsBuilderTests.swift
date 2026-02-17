//
//  ConnectivityBarrierSettingsBuilderTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 09/01/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ConnectivityBarrierSettingsBuilderTests: XCTestCase {

    func test_setWifiOnly_sets_wifi_only() {
        let builder = ConnectivityBarrierSettingsBuilder()
        let result = builder.setWifiOnly(true).build()

        let configuration = result.getDataDictionary(key: BarrierSettings.Keys.configuration)
        XCTAssertEqual(configuration?.get(key: ConnectivityBarrierConfiguration.Keys.wifiOnly), true)
    }

    func test_inheritance_from_base_builder_works() {
        let result = ConnectivityBarrierSettingsBuilder()
            .setScopes([.all])
            .setWifiOnly(true)
            .build()

        XCTAssertEqual(result.getArray(key: BarrierSettings.Keys.scopes), ["all"])
        let configuration = result.getDataDictionary(key: BarrierSettings.Keys.configuration)
        XCTAssertEqual(configuration?.get(key: ConnectivityBarrierConfiguration.Keys.wifiOnly), true)
    }
}
