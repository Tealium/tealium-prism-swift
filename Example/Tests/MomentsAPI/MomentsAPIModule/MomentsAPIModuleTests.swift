//
//  MomentsAPIModuleTests.swift
//  MomentsAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class MomentsAPIModuleTests: MomentsAPIModuleBaseTests {

    // MARK: - Basic Module Tests

    func test_module_id_is_correct() {
        XCTAssertEqual(module.id, MomentsAPIModule.moduleType)
    }

    func test_module_version_is_not_empty() {
        XCTAssertFalse(module.version.isEmpty)
    }

    // MARK: - Configuration Update Tests

    func test_updateConfiguration_returns_nil_for_invalid_configuration() {
        let invalidConfigs: [DataObject] = [
            [:], // Missing region
            [MomentsAPIConfiguration.Keys.referrer: ""], // Missing region
            [MomentsAPIConfiguration.Keys.region: 12_345] // Invalid region type
        ]

        for config in invalidConfigs {
            let updatedModule = module.updateConfiguration(config)
            XCTAssertNil(updatedModule, "Should return nil for invalid configuration: \(config)")
        }
    }

    func test_updateConfiguration_returns_self_for_valid_configuration() {
        let validConfigs: [DataObject] = [
            [MomentsAPIConfiguration.Keys.region: "invalid-region"], // Invalid region string creates custom region
            MomentsAPISettingsBuilder().setRegion(.germany).setReferrer("https://valid.com").build()
                .getDataDictionary(key: "configuration")?.toDataObject() ?? [:]
        ]

        for config in validConfigs {
            let updatedModule = module.updateConfiguration(config)
            XCTAssertNotNil(updatedModule, "Should return self for valid configuration: \(config)")
            XCTAssertTrue(updatedModule === module)
        }
    }

    // MARK: - Referrer Configuration Tests

    func test_module_uses_custom_referrer_when_provided() throws {
        try executeModuleReferrerTests(configReferrer: "https://custom-referrer.com", expectedReferrer: "https://custom-referrer.com")
    }

    func test_module_uses_default_referrer_when_nil() throws {
        try executeModuleReferrerTests(configReferrer: nil, expectedReferrer: "https://tags.tiqcdn.com/utag/\(account)/\(profile)/\(environment)/mobile.html")
    }

    func test_module_uses_empty_referrer_when_provided_empty() throws {
        try executeModuleReferrerTests(configReferrer: "", expectedReferrer: "")
    }

    func executeModuleReferrerTests(configReferrer: String?, expectedReferrer: String) throws {
        let expectation = expectation(description: "Request uses expected referrer")
        self.configuration = MomentsAPIConfiguration(region: .usEast,
                                                     referrer: configReferrer)

        let disposableContainer = DisposableContainer()
        try mockNetworkHelper.encodeResult(EngineResponse())
        mockNetworkHelper.requests.subscribe { request in
            guard case .get(_, _, let headers) = request,
                  let headers = headers else {
                return
            }
            XCTAssertEqual(headers["Referer"], expectedReferrer)
            disposableContainer.dispose()
            expectation.fulfill()
        }.addTo(disposableContainer)
        module.fetchEngineResponse(engineID: "test-engine") { _ in }
        waitForDefaultTimeout()
    }

    // MARK: - Initialization Tests

    func test_required_convenience_init_returns_nil_with_empty_configuration() {
        let module = MomentsAPIModule(context: mockContext, moduleConfiguration: [:])
        XCTAssertNil(module, "Should return nil when configuration is empty (missing required region)")
    }

}
