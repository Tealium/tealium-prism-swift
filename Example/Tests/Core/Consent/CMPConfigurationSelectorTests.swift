//
//  CMPConfigurationSelectorTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 22/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class CMPConfigurationSelectorTests: XCTestCase {
    @StateSubject(nil)
    var consentSettings: ObservableState<ConsentSettings?>
    let adapter = MockCMPAdapter(id: "vendor1", consentDecision: nil)
    lazy var selector = CMPConfigurationSelector(consentSettings: consentSettings,
                                                 cmpAdapter: adapter,
                                                 queue: .main)

    func test_configuration_is_selected_when_vendorId_is_same_as_adapter_id() {
        let config = ConsentConfiguration(tealiumPurposeId: "tealium",
                                          refireDispatchersIds: [],
                                          purposes: [:])
        _consentSettings.value = ConsentSettings(configurations: ["vendor1": config])

        let result = selector.configuration.value
        XCTAssertEqual(result?.tealiumPurposeId, config.tealiumPurposeId)
        XCTAssertEqual(result?.refireDispatchersIds, config.refireDispatchersIds)
        XCTAssertEqual(result?.purposes, config.purposes)
    }

    func test_configuration_is_not_selected_when_vendorId_is_not_same_as_adapter_id() {
        let config = ConsentConfiguration(tealiumPurposeId: "tealium",
                                          refireDispatchersIds: [],
                                          purposes: [:])
        _consentSettings.value = ConsentSettings(configurations: ["vendor2": config])

        let result = selector.configuration.value
        XCTAssertNil(result)
    }

    func test_inspector_is_null_until_configuration_and_decision_are_provided() {
        XCTAssertNil(selector.consentInspector.value)
        adapter.applyDecision(ConsentDecision(decisionType: .implicit, purposes: []))
        let config = ConsentConfiguration(tealiumPurposeId: "tealium",
                                          refireDispatchersIds: [],
                                          purposes: [:])
        XCTAssertNil(selector.consentInspector.value)
        _consentSettings.value = ConsentSettings(configurations: ["vendor1": config])
        XCTAssertNotNil(selector.consentInspector.value)
    }
}
